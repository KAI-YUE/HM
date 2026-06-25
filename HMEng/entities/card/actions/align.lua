local bS, bW = "Strong", "Weak"
local Y, N   = true, false

return function (Card)
-------------------------------------------
--- align
-------------------------------------------
function Card:align()
    local ch = self.children;           local cfsp = ch.floating_sprite
    if cfsp then local spT, T = cfsp.T, self.T; spT.y, spT.x, spT.r = T.y, T.x, T.r  end
    if ch.focused_ui then ch.focused_ui:set_alignment() end
end

---------------------------------------
--- align hover pop 
---------------------------------------
function Card:align_h_popup()
    local gm, ch, zone, dir = self.gm, self.children, self.zone, "tm"
    local focused_ui, acfg  = ch.focused_ui and Y or N, zone and zone.config

    if ch.buy_button or (acfg.view_deck) or (acfg.type == "shop") then dir = "cl"
    elseif self.T.y < gm.card_h * 0.8 then dir = "bm" end

    local offset, ab = { x = 0, y = 0 }, self.ability
    if dir ~= "cl" then offset.x = 0
    else if       focused_ui   then offset.x = -0.05
         elseif ab.consumable  then offset.x = 0 end
    end

    if focused_ui then
        if     dir == "tm"  then if zone and zone == gm.hand then offset.y = -0.08 else offset.y = -0.15 end
        elseif dir == "bm"  then offset.y = 0.12  else offset.y = 0 end
    else if    dir == "tm"  then offset.y = -0.13 elseif dir == "bm" then offset.y = 0.1 end end

    local _m = ch.focused_ui or self
    local res = { major = _m, parent = self, xy_bond = bS, r_bond = bW, wh_bond = bW, offset = offset, type = dir }

    return res
end

end