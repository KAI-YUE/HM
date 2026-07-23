-- local UIPanel     = require("HMEng.ui_actors.ui_panel")    = require("HMEng.ui_actors.ui_panel")
local JokerWin   = require("HMfns.profiles.gallery.joker_win")
local TabUtils   = require("HMfns.utils.table_utils")
local Overstock  = require("HMGplay.shop.stock")

local inc_shop_size = Overstock.inc_shop_size
local wipe, push    = TabUtils.wipe, table.insert
local _j_sticker    = JokerWin.fetch_joker_win_sticker

local min, max  = math.min, math.max

local Y, N = true, false

return function (Card)
----------------------------------------
--- Update 
----------------------------------------
--__________________________
--- Main: update 
--__________________________
function Card:update(dt)
    local gm, ff, sfacing = self.gm, self.flipping, self.sprite_facing 
    local pinch_w = (self.pinch and self.pinch.min_w) or 0
    if ff == "f2b" then if self.VT.w <= pinch_w then self.sprite_facing, self.pinch.x = "back",  N  end end
    if ff == "b2f" then if self.VT.w <= pinch_w then self.sprite_facing, self.pinch.x = "front", N end end

    local st, ch = self.states, self.children
    if not st.focus.is and ch.focused_ui then ch.focused_ui:remove(); ch.focused_ui = nil end

    local ab, cfg   = self.ability, self.config
    local set, cons = ab.set, ab.consumable

    local aname, zone = ab.name, self.zone 

    if cons and cons.max_highlighted then cons.mod_num = min(5, cons.max_highlighted) end     
    if ab and ab.perma_debuff then self.debuff = Y end

    local _j, _c = gm.jokers, gm.consumables
    if zone and ((zone == _j) or (zone == _c)) then self.bypass_lock, self.bypass_discovery_center, self.bypass_discovery_ui = Y, Y, Y end
    self.sell_cost_label = (self.facing == "back" and "?") or self.sell_cost
end

end
