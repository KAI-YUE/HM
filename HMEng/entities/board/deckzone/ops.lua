local Y, N = true, false
local min = math.min

return function (DeckZone)
--------------------------------------------------
--- card hooks
--------------------------------------------------
--- Helpers: insert card | overview card limit 
function DeckZone:_insert_card(card)     table.insert(self.cards, 1, card) end
function DeckZone:_overflow_card_limit() self.config.card_limit = #self.cards end
function DeckZone:_remove_discard_card(_cards) return _cards[1] end

--- Helper: post emplace 
function DeckZone:_post_emplace(card, stay_flipped)
    if self.projected_quad_source    then self:assign_quad(nil, card) end
    if card.sprite_facing == "front" then card:build_front_canvas() end
end

--- Helper: set card sets 
function DeckZone:_set_card_sts(card) local cst = card.states; cst.drag.can, cst.collide.can = N, N end

-------------------------------------------------------
--- update
-------------------------------------------------------
function DeckZone:update(dt)
    DeckZone.super.update(self, dt)

    local gm, cfg, st = self.gm, self.config, self.states
    for _, k in ipairs({ "collide", "hover", "click" }) do st[k].can = Y end
    if cfg.card_limit > #gm.run_card_id then cfg.card_limit = #gm.run_card_id end

    if not self:is_deck() then return end

    --- deck hover easing
    local target = (st.hover.is or self.deck_hover_extended) and 1 or 0
    local speed  = cfg.hover_speed or 9
    local step   = min(1, (dt or 0)*speed)
    local old_hover_t = self.hover_t or 0
    self.hover_t = old_hover_t + (target - old_hover_t)*step
    if self.hover_t ~= old_hover_t then self:mark_card_layout_dirty(); if gm.hand then gm.hand:mark_card_layout_dirty() end end
    self:update_hover_controls()
end

end
