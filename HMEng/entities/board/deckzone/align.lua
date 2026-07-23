local max, min, ceil = math.max, math.min, math.ceil

local Y, N = true, false

return function (DeckZone)
------------------------------------------------------
--- align_cards
------------------------------------------------------
--- Helper: hover_amount 
local function _hover_amount(self) return max(0, min(1, self.hover_t or 0)) end

--- Helper: _share_index
local function _share_index(k, count)
    if count <= 0 then return 2 end
    local share_size = max(1, ceil(count/3))
    return min(3, ceil(k/share_size))
end

--- Helper: _hover_share_pose
local function _hover_share_pose(self, card, k, count)
    local h      = _hover_amount(self);                      if h <= 0 then return 0, 0, 0 end
    local share  = _share_index(k, count)
    local center = share - 2
    local cT     = card.T

    local lift   = -(self.config.hover_lift or 0.16)*cT.h
    local spread =  (self.config.hover_spread or 0.10)*cT.w
    local fan_r  =  (self.config.hover_fan_r or 0.055)
    return center*spread*h, lift*h, center*fan_r*h
end

---__________________________________________________
--- main: align_cards
---__________________________________________________
function DeckZone:align_cards()
    local cfg, T, _sc   = self.config, self.T, self.cards
    local samt          = self.shuffle_amt or 0
    local deck_height   = cfg.deck_height or (self.card_d*max(#_sc, 60));
    local stack_divisor = cfg.stack_divisor or 1

    local count = #_sc
    for k, card in ipairs(_sc) do
        if card.states.drag.is then goto continue end

        local cT, sp      = card.T, self.shadow_parallax
        local jitter      = (k%2 == 1 and 1 or 0)
        local dh          = deck_height*(count/stack_divisor - k)
        local hx, hy, hr  = _hover_share_pose(self, card, k, count)

        cT.x = T.x + 0.5*(T.w - cT.w)  + sp.x*dh + samt*jitter + hx
        cT.y = T.y + 0.35*(T.h - cT.h) + sp.y*dh + hy
        cT.r = T.r + 0.3*samt*(1 + k*0.05)*jitter + hr
        cT.x = cT.x + card.shadow_parallax.x/30
        if self.assign_quad then self:assign_quad(nil, card) end
        ::continue::
    end

    for k, card in ipairs(_sc) do card.rank = k end
    self.card_layout_dirty = N
end

end
