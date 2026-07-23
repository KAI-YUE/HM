local Actor      = require("HMEng.actors.actor")
local Unlock     = require("HMfns.systems.unlocks")
local TabUtils   = require("HMfns.utils.table_utils")
local CardFront  = require("HMEng.entities.card.card_front")
local Spritor    = require("HMEng.actors.spritor")

local handle_unlock_request  = Unlock.handle_unlock_request
local contains, deep_copy    = TabUtils.contains, TabUtils.deep_copy
local _pick, push            = TabUtils.random_pick, table.insert
local max, floor             = math.max, math.floor

local Tst    = { "hover", "click", "drag"  }
local Y, N   = true, false

return function (Card)
------------------------------------------
--- hard set T
------------------------------------------
function Card:hard_set_T(x, y, w, h)
    local T, ch = self.T, self.children
    local x, y, w, h = x or T.x, y or T.y, w or T.w, h or T.h
    Actor.hard_set_T(self, x, y, w, h)

    local front, back, center = ch.front, ch.back, ch.template
    if front then front:hard_set_T(x, y, w, h) end
    back:hard_set_T(x, y, w, h)
    center:hard_set_T(x, y, w, h)
end

------------------------------------------------------
--- Set sprite 
-----------------------------------------------------
--- Helper: set front sprite 
function Card:_front_sprite()
    local gm, ch  = self.gm, self.children;      if ch.front and not ch.front._dirty then return end
    local TA,  T  = gm.T_atlas, self.T;          

    ch.front      = CardFront(gm, T.x, T.y, T.w, T.h, self.config.card or self.base)
    local chf     = ch.front
    local cst, st = chf.states, self.states
    
    for _, k in ipairs(Tst) do cst[k] = st[k] end 
    cst.collide.can = N
    chf:set_role({ major = self, role_type = "Glued", draw_major = self })
    chf:glue_to_major(self)
end

--- Helper: undiscovered pos
function Card:undiscovered_pos(gm, _template)
    local set = _template.set
    if set == "Edition"  then return gm.j_undiscovered.pos end 
end

--- Helper: post_crop
function Card:_post_crop(_template)
    local _name, _dis = _template.name, (_template.discovered or self.bypass_discovery_template)
    if not _dis or not contains(Tsize, _name) then return end 
    local ct = self.children.template
    if _name == "Half"   and _dis then ct.scale.y = ct.scale.y/1.7; return end
end

--- Helper: template_set 
function Card:_template_set(_template)
    local gm, ch, T    = self.gm, self.children, self.T
    local TA, ct, cfg  = gm.T_atlas, ch.template, self.config
    local _set, template = _template.set, cfg.template
    local AA = gm.a_atlas

    -- handle locked?
    local params, set  = self.params, template.set
    local bypass, _dis = params.bypass_discovery_template, contains(Teb, _template.set) and not _template.discovered
    local x, y, w, h   = T.x, T.y, T.w, T.h

    ch.template = Spritor(gm, x, y, w, h, TA.cards, "card_back_0", N)

    local ct = ch.template;       local ctst, st = ct.states, self.states; 
    for _, v in ipairs(Tst) do ctst[v] = st[v] end

    ct.states.collide.can = N
    ct:set_role({ major = self, role_type = "Glued", draw_major = self })
    self:_post_crop(_template, ct)
    ct:glue_to_major(self)
end

--- Helper: children back 
function Card:_ch_back()
    local gm, ch, T, st  = self.gm, self.children, self.T, self.states
    local TA, x, y, w, h = gm.T_atlas, T.x, T.y, T.w, T.h

    ch.back = Spritor(gm, x, y, w, h, TA.cards, "card_back_1", N)
    local chb = ch.back;                            local _st = chb.states
    for _, v in ipairs(Tst) do _st[v] = st[v] end
    _st.collide.can = N
    chb:set_role({ major = self, role_type = "Glued", draw_major = self })
end

--- Helper: set template sprite
function Card:_template_sprite(_template)
    if _template.set          then self:_template_set(_template) end
    if not self.children.back then self:_ch_back() end
end

--___________________________________
--- Main: set sprite
--___________________________________
function Card:set_sprites(_template, _front)
    if _front    then self:_front_sprite() end
    if _template then self:_template_sprite(_template) end
end

--------------------------------------------------------------
--- Set ability
-------------------------------------------------------------
--- Helper: ad-hoc adjust 
function Card:_adhoc_adj(center, _cdis, T)
    local name = center and center.name
    local _dis = _cdis or self.bypass_discovery_center
    if name == "Half"   and _dis then T.h = T.h/1.7 end
end

--- Helper: init ability
function Card:_init_ability(center)
    local cfg, bL = center.config, { "name", "effect", "set" }
    local cL = { "mult", "h_mult", "h_x_mult", "h_dollars", "p_dollars", "t_mult", "t_chips", "h_size", "d_size"  }

    self.ability = self.ability or {};                local ab = self.ability
    for _, b in ipairs(bL) do ab[b] = center[b] end 
    for _, c in ipairs(cL) do ab[c] = cfg[c] or 0 end

    ab.x_mult, ab.extra, ab.perma_bonus = cfg.Xmult or 1, deep_copy(cfg.extra), ab.perma_bonus
    ab.extra_value, ab.type             = 0, cfg.type or ""
    ab.order, ab.forced_selection       = center.order, ab and ab.forced_selection

    ab.bonus = (ab.bonus or 0) + (cfg.bonus or 0)
    if center.consumable then ab.consumable = center.config end
end

--- Helper: handle gold card
function Card:_handle_gold_card()
    local an, _s, _p = self.ability.name, self.seal == "Gold", self.playing_card
    if an == "Gold Card" and _s == "Gold" and _p then handle_unlock_request(self.gm, { type = "double_gold" }) end
    self:set_cost()
end

--- Helper: set label 
function Card:_set_label(center)
    local ab, cfg    = self.ability, self.config
    ab.hands_played_at_create = gG and gG.hands_played or 0
    local set, aname = ab.set, ab.name

    self.label = center.label or cfg.card.label or ab.set
end

--_______________________________
--- Main: set ability
--_______________________________
function Card:set_ability(center, initial, delay_sprites)
    local gm, T, cfg  = self.gm, self.T, self.config;   
    local params, Fs  = self.params, gm.Fs;          
    local _cdis, gG   = center and center.discovered, gm.GAME
    local EM, gUI, ab = gm.E_MANAGER, gm.UI, self.ability
    local old_center  = cfg.template
    
    cfg.template, self.sticker_run, self.base_cost = center, nil, center and center.cost or 1

    for k, v in pairs(gm.CMod) do if center == v then cfg.center_key = k end end
    if params.discover and not _cdis then F.unlock(gm, center); Fs.register_card_discovery(gm, center) end

    self:_adhoc_adj(center, _cdis, T)

    if delay_sprites then EM:enqueue_event({ func = function() if not self.REMOVED then self:set_sprites(center) end; return Y end })  
    else self:set_sprites(center) end
    if ab and old_center and old_center.config.bonus then ab.bonus = ab.bonus - old_center.config.bonus end
    
    self:_init_ability(center)
    self:_set_label(center)
end

---------------------------------------------
--- Set cost 
---------------------------------------------
function Card:set_cost()
    local gm = self.gm;                     local gG  = gm.GAME
    self.extra_cost = 0 + gG.inflation;     local _ed = self.edition
    if _ed then
        local _h, _f = _ed.holo and  3 or 0,      _ed.foil and 2 or 0 
        local _p, _n = _ed.polychrome and 5 or 0, _ed.negative and 5 or 0
        self.extra_cost = self.extra_cost + _h + _f + _p + _n
    end
    self.cost = max(1, floor((self.base_cost + self.extra_cost + 0.5)*(100-gG.discount_percent)/100))

    local ab = self.ability;                local set, SET, F = ab.set, gm.SET, gm.Fs
    local aname = ab.name;                  

    if ab.rental then self.cost = 1 end
    
    local zone = self.zone                  -- sell cost 
    self.sell_cost = max(1, floor(self.cost/2)) + (ab.extra_value or 0)
    if zone and ab.couponed and (zone == gm.shop_jokers or zone == shop_booster) then self.cost = 0 end
    self.sell_cost_label = (self.facing == "back" and "?") or self.sell_cost
end

end
