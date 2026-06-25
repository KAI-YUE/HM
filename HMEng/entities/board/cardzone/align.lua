local TabUtils = require("HMfns.utils.table_utils")
local Actor    = require("HMEng.actors.actor")

local sfind = string.find
local wipe  = TabUtils.wipe

local Y, N = true, false

return function (CardZone)
------------------------------------------------------
--- Hard set T
------------------------------------------------------
function CardZone:hard_set_T(x, y, w, h)
    local T = self.T
    x, y, w, h = x or T.x, y or T.y, w or T.w, h or T.h
    
    Actor.hard_set_T(self, x, y, w, h)
    self:calculate_parallax()
    self:align_cards()
    self:hard_set_cards()
    self.card_layout_dirty = N
end

-----------------------------------------
--- Hard set cards 
-----------------------------------------
function CardZone:hard_set_cards() for _, card in pairs(self.cards) do card:hard_set_T(); card:calculate_parallax() end end

------------------------------------------
--- Align discard 
------------------------------------------
function CardZone:_align_discard(_sc)
    local T = self.T
    for _, card in ipairs(_sc) do
        if card.facing == "front" then card:flip() end

        if card.states.drag.is then return end
        local cT, dpos = card.T, card.discard_pos
        cT.x = T.x + (T.w - T.w)*dpos.x
        cT.y = T.y + (T.h - T.h)*dpos.y
        cT.r = dpos.r
    end
end

------------------------------------------
--- Align cards
------------------------------------------
function CardZone:align_cards(args)
    local type, _sc = self.config.type, self.cards
    if type == "discard" then self:_align_discard(_sc) end
    for k, card in ipairs(_sc) do card.rank = k end
    self.card_layout_dirty = N
end

-----------------------------------------
--- destroy_offsets
----------------------------------------
function CardZone:destroy_offsets(key)
    if sfind(key, "x") then self.fan_anchor_x_by_size = wipe(self.fan_anchor_x_by_size) end
    if sfind(key, "y") then self.fan_anchor_y_by_size = wipe(self.fan_anchor_y_by_size) end
    if sfind(key, "r") then
        self.fan_grab_angle_jitter_deg = wipe(self.fan_grab_angle_jitter_deg)
        self.fan_grab_pad_by_index = wipe(self.fan_grab_pad_by_index)
    end
end

end
