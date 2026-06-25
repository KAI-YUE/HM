
local Actor    = require("HMEng.actors.actor")
local DD       = require("HMGplay.cards.draw_deal")
local TabUtils = require("HMfns.utils.table_utils")

local contains      = TabUtils.contains
local deep_copy     = TabUtils.deep_copy
local push, tsort   = table.insert, table.sort
local draw_from_to  = DD.draw_from_to

local abs           = math.abs
local max, min      = math.max, math.min

local Tpsc  = { "play" }
local Tst   = { "collide", "hover", "click" }
local Y, N  = true, false

return function (CardZone)
--------------------------------------------------
--- card hooks
--------------------------------------------------
function CardZone:_insert_card(card)                  push(self.cards, card) end
function CardZone:_overflow_card_limit()              end
function CardZone:_can_overfill_on_draw()             return N end
function CardZone:_prepare_stay_flipped(stay_flipped) return stay_flipped end
function CardZone:_can_refill_on_size_change()        return N end
function CardZone:_post_update(dt)                    end
function CardZone:_post_emplace(card, stay_flipped)   end
function CardZone:is_deck()                           return self.config and self.config.type == "deck" end
function CardZone:is_hand()                           return self.config and self.config.type == "hand" end

--------------------------------------------------
--- layout dirty
--------------------------------------------------
--- Helper: mark layout dirty
function CardZone:mark_card_layout_dirty()
    local gm = self.gm; if gm and gm.mark_zone_layout_dirty then gm:mark_zone_layout_dirty(self, "card"); return end
    self.card_layout_dirty = Y; if self.wake_move then self:wake_move() end
end

--- Helper: card layout is live
local function _card_layout_is_live(self)
    local cfg, gm = self.config or {}, self.gm
    local deck, ctrl = gm and gm.deck, gm and gm.CTRL
    if self:is_hand() and ctrl and ctrl.locks and ctrl.locks.hand_anim then return Y end
    if self:is_hand() and deck and (deck.hover_t or 0) > 0.001 then return Y end
    if self:is_deck() and ((self.hover_t or 0) > 0.001 or self.deck_hover_extended) then return Y end
    for _, card in ipairs(self.cards or {}) do
        local st = card.states
        if st and ((st.hover and st.hover.is) or (st.drag and st.drag.is) or (st.focus and st.focus.is)) then return Y end
    end
    return cfg.live_layout == Y
end

--- Helper: flush layout
function CardZone:flush_card_layout()
    local live, was_live = _card_layout_is_live(self), self.card_layout_live
    self.card_layout_live = live
    if not (self.card_layout_dirty or live or was_live) then return end
    self:align_cards()
    self.card_layout_dirty = N
end

----------------------------------------------------
--- set card sts 
----------------------------------------------------
function CardZone:_set_card_sts(card)
    local cst = card.states;            cst.collide.can = Y
    if contains(Tpsc, self.config.type) then cst.drag.can = N else cst.drag.can = Y end
end

--------------------------------------------------
--- wire_to_field
--------------------------------------------------
function CardZone:wire_to_field(source_zone, args)
    local cfg = args or {}
    self.projected_quad_source  = source_zone
    self.projector              = source_zone and source_zone.projector 
    self.projected_quad_coords  = cfg.quad_coords or self.projected_quad_coords or { row = 1, col = 1 }
end

--------------------------------------------------
--- assign_quad
--------------------------------------------------
local function _estimate_quad_width(quad)
    local tl, tr, br, bl  = quad[1], quad[2], quad[3], quad[4];  if not (tl and tr and br and bl) then return 0 end
    local top_w,  bot_w   = abs(tr.x - tl.x), abs(br.x - bl.x)
    return 0.5*(top_w + bot_w)
end

--- Helper: tailor quad to card
local function _tailor_quad_to_card(quad, card)
    if not quad or not quad[1] then return end

    local anchor, tailored = quad[1], deep_copy(quad)
    for i = 1, 4 do tailored[i].x, tailored[i].y = quad[i].x - anchor.x, quad[i].y - anchor.y  end

    local card_w, quad_w = card and card.T and card.T.w or 0, _estimate_quad_width(tailored)
    if quad_w <= 0 or card_w <= 0 then return tailored end

    local scale = 1.1 * card_w/quad_w

    for i = 1, 4 do tailored[i].x, tailored[i].y = tailored[i].x*scale, tailored[i].y*scale end
    return tailored
end

---______________________________________
--- main: assign_quad
---______________________________________
function CardZone:assign_quad(quad_coords, card)
    local source,   coords      = self.projected_quad_source, quad_coords or self.projected_quad_coords or { row = 1, col = 1 }
    local row,      col         = coords.row or 1, coords.col or 1
    self.projected_quad_coords  = { row = row, col = col }

    local quad = source and source.get_projected_quad_at and source:get_projected_quad_at(row, col)
    quad = _tailor_quad_to_card(quad, card)

    if not card then return quad end
    if self:is_deck() then card:promote_to_deck_card()
    else                   card:promote_to_field_card() end
    return card:assign_field_quad(quad)
end

---_______________________________
--- main: emplace
---_______________________________
function CardZone:emplace(card, stay_flipped)
    local cfg = self.config
    self:_insert_card(card)

    if #self.cards > cfg.card_limit then self:_overflow_card_limit() end
    card:set_zone(self)                        
    self:set_zone_sts()
    self:align_cards()
    self.card_layout_dirty = N

    self:_post_emplace(card, stay_flipped)
end

-------------------------------------------
--- Set ranks 
-------------------------------------------
function CardZone:set_zone_sts() for k, card in ipairs(self.cards) do card.rank = k; self:_set_card_sts(card) end end

--------------------------------------------------
--- sort
--------------------------------------------------
function CardZone:sort(method)
    local cfg = self.config
    cfg.sort = method or cfg.sort;      local _s = cfg.sort
    
    if     _s == "desc"      then tsort(self.cards, function (a, b) return a:get_nominal() > b:get_nominal() end ); 
    elseif _s == "asc"       then tsort(self.cards, function (a, b) return a:get_nominal() < b:get_nominal() end )
    elseif _s == "suit desc" then tsort(self.cards, function (a, b) return a:get_nominal("suit") > b:get_nominal("suit") end )
    elseif _s == "suit asc"  then tsort(self.cards, function (a, b) return a:get_nominal("suit") < b:get_nominal("suit") end ) end
    self:mark_card_layout_dirty()
end

-----------------------------------------------------
--- change_size 
----------------------------------------------------
-- Helper: _apply_delta
function CardZone:_apply_delta(gm, delta)
    local cfg = self.config
    cfg.real_card_limit = (cfg.real_card_limit or cfg.card_limit) + delta
    cfg.card_limit = math.max(0, cfg.real_card_limit)
    if delta <= 0 or cfg.real_card_limit <= 1 or not self:_can_refill_on_size_change() then return Y end 
    
    local ST, STS = gm.g_state, gm.g_states
    if not self.cards[1] or (ST ~= STS.draw_hand and ST ~= STS.select_hand) then return Y end  
    
    local card_count = abs(delta)
    for i = 1, card_count do
        draw_from_to(gm, gm.deck, gm.hand, i*100/card_count, nil, nil, nil, 0.07)
        gm.E_MANAGER:enqueue_event({ func = function() self:sort() return Y end })
    end
    self:mark_card_layout_dirty()
    return Y
end

--________________
-- main 
--________________
function CardZone:change_size(delta)
    if delta == 0 then return end;      local gm = self.gm
    gm.E_MANAGER:enqueue_event({ func = function() return self:_apply_delta(gm, delta) end})
end

--------------------------------------------------------
-- move 
--------------------------------------------------------
function CardZone:move(dt)
    local was_new_align = self.new_align
    Actor.move(self, dt)
    if was_new_align then self:mark_card_layout_dirty() end
    self:flush_card_layout()
end

-------------------------------------------------------
--- update
-------------------------------------------------------
function CardZone:update(dt)
    local gm = self.gm
    
    if gm.CTRL.HID.controller and not self:is_hand() then self:unhighlight_all() end  -- Check and see if controller is being used
    self:_post_update(dt)
end

end
