local TableUtils   = require("HMfns.utils.table_utils")
local SND, HandEva = require("HMfns.utils.sound_utils"), require("HMGplay.rules.hand_eva")

-- local HUD_update_hand_label = HUDMgr.update_hand_label
local hand_info, play_clip  = HandEva.poker_hand_info, SND.play_clip
local contains, push        = TableUtils.contains, table.insert

local Tzone = { "hand", "consumable" }
local Y, N  = true, false

return function (CardZone)
---------------------------------------
--- can highlight 
---------------------------------------
function CardZone:can_highlight(card)
    local gm, cfg, Ctrl = self.gm, self.config, self.Ctrl;       local type = cfg.type
    if Ctrl.HID.controller   then if type == "hand" then return Y end end
    if contains(Tzone, type) then return Y end
    return N
end

-----------------------------------------------
--- add to highlight
-----------------------------------------------
function CardZone:add_to_highlighted(card, silent)
    local gm, cfg, _p = self.gm, self.config, not silent
    local type, _h    = cfg.type, self.highlighted

    if #_h >= cfg.highlighted_limit then card:highlight(N)
    else push(_h, card);  card:highlight(Y);  self:mark_card_layout_dirty(); if _p then play_clip(gm, "cardSlide1") end end
    
    if self ~= gm.hand or gm.g_state ~= gm.g_states.select_hand then return end 
    self:parse_highlighted()
end

-----------------------------------------------
--- parse highlighted 
-----------------------------------------------
function CardZone:parse_highlighted()
    local gm, _h = self.gm, self.highlighted
    local text, disp_text, poker_hands = hand_info(gm, _h)
    if text == "NULL" then HUD_update_hand_label(gm, { immediate = Y, nopulse = N, delay = 0 }, { mult = 0, chips = 0, level = "", handname = "" }); return end     
end

-----------------------------------------------
--- remove from highlighted 
-----------------------------------------------
function CardZone:remove_from_highlighted(card, force)
    local gm = self.gm;         local hand = gm.hand
    if (not force) and card and card.ability.forced_selection and self == hand then return end
    
    local _h = self.highlighted
    for i = #_h, 1, -1 do if _h[i] == card then table.remove(self.highlighted, i); break end end
    card:highlight(N)
    self:mark_card_layout_dirty()
    if self == hand and gm.g_state == gm.g_states.select_hand then self:parse_highlighted() end
end

-----------------------------------------------
--- unhighlight all
-----------------------------------------------
function CardZone:unhighlight_all()
    local gm, _h = self.gm, self.highlighted;       local hand = gm.hand
    for i = #_h, 1, -1 do
        if _h[i].ability.forced_selection and self == hand then
        else _h[i]:highlight(N); table.remove(self.highlighted, i); self:mark_card_layout_dirty() end
    end 
    if self == hand and gm.g_state == gm.g_states.select_hand then self:parse_highlighted() end
end

end
