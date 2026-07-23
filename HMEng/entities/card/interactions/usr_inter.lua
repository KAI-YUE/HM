local GameObj  = require("HMEng.actors.game_obj")
local SND      = require("HMfns.utils.sound_utils")
-- local UIPanel     = require("HMEng.ui_actors.ui_panel")  = require("HMEng.ui_actors.ui_panel")
local TabUtils = require("HMfns.utils.table_utils")

local rand, rand_pick = math.random, TabUtils.random_pick
local abs, cos, sin   = math.abs, math.cos, math.sin
local wipe = TabUtils.wipe
local play_clip = SND.play_clip
local T_woffset = { 1/2, 1/4, 1/8, 0 } 
local Y, N = true, false

return function (Card)
-----------------------------
--- hover layout
----------------------------
--- Helper: wake hover layout
local function _wake_hover_layout(card)
    local zone = card and card.zone
    if zone and zone.mark_card_layout_dirty then zone:mark_card_layout_dirty() end
end

----------------------------------------------
--- update (hover) tilt with quantization 
----------------------------------------------
function Card:_update_tilt(TV, cpos, ho, _tf)
    local CTRL, center, T  = self.Ctrl, self.center, self.T
    local pc, _cx, _cy, w  = CTRL.p_cursor, center.x, center.y, T.w
    local CT, p,   offs    = pc.T, {}, self.offset
    local cx, cy, hx, hy   = cpos.x, cpos.y, ho.x, ho.y
    
    p.x, p.y = CT.x, CT.y;      
    self:_to_container(p);      offs.wo = offs.wo or rand_pick(T_woffset)

    TV.mx, TV.my, TV.amt = _cx + w*offs.wo, _cy, _tf
end

----------------------------------------------
--- update idle tilt with a virtual cursor
----------------------------------------------
function Card:_update_idle_tilt(TV, now, _tf)
    local strength = self.idle_tilt;       if not strength then return N end

    local ID, VT, R       = self.ID, self.VT, self.gm._room
    local RT, tilt_angle  = R.T, now*(1.56 + (ID/1.14)%1) + ID/1.35

    TV.mx  = (0.5 + 0.5*strength*cos(tilt_angle))*VT.w + VT.x + RT.x
    TV.my  = (0.5 + 0.5*strength*sin(tilt_angle))*VT.h + VT.y + RT.y
    TV.amt = strength*(0.5 + cos(tilt_angle))*_tf
end

--------------------------------------
--- Hover  
--------------------------------------
function Card:hover()
    local gm, st, ch = self.gm, self.states, self.children
    play_clip(gm, "paper1", 0.2*rand() + 0.9, 0.35)

    if self.facing ~= "front" or self.no_ui then return end
    if st.drag.is and not gm.CTRL.HID.touch then return end 

    local ch, cfg = self.children, self.config
    if ch.alert and not cfg.template.alerted then cfg.template.alerted = Y; gm:save_progress() end
    
    local EM, T, offset = gm.E_MANAGER, self.T, self.offset
    offset.ro = offset.ro or (-rand()/6 - 0.05)
    local ro  = offset.ro
    if self.highlighted then ro = ro/2 end 
    EM:enqueue_event({ trigger = "ease", ease = "elastic", delay = 0.4, blockable = N, ref_table = T, ref_value = "r", ease_to = T.r + ro/2,
        func = function(v) if not st.hover.is then return T.r end; return v end })
end

--------------------------------------
--- Stop hover
--------------------------------------
function Card:stop_hover() wipe(self.offset); self.hover_offset.x, self.hover_offset.y = 0, 0; local tv = self.tilt_var; if tv then tv.amt = 0 end; _wake_hover_layout(self) end

--------------------------------------
--- Click 
--------------------------------------
function Card:click() 
    local gm, zone = self.gm, self.zone;         if not zone then return end 
    if not zone.can_highlight or not zone:can_highlight(self) then return end 

    local hand = self.hand
    if (zone == hand) and (gm.g_state == gm.g_states.hand_played) then return end
    if self.highlighted ~= Y then zone:add_to_highlighted(self)
    else zone:remove_from_highlighted(self); play_clip(gm, "cardSlide2", nil, 0.3) end
end

-----------------------------------------
--- highlight
-----------------------------------------
function Card:highlight(is_highlighted) self.highlighted = is_highlighted end

-----------------------------------------
--- highlight tilt
-----------------------------------------
function Card:highlighted_tilt()
    if not self.highlighted then return N end
    local T = self.T
    T.r = T.r + 0.08
end

-----------------------------------------
--- unhighlight tilt
-----------------------------------------
function Card:unhighlighted_tilt()
    if self.highlighted then return N end
    local T = self.T;       T.r = T.r - 0.08
end

--------------------------------------
--- Release 
--------------------------------------
function Card:release(dragged) if dragged:is(Card) and self.zone then self.zone:release(dragged) end end 

-----------------------------------
--- flip
----------------------------------
function Card:flip()
    local ff, pinch = self.facing, self.pinch
    if ff == "front" then  self.flipping, self.facing, pinch.x = "f2b", "back", Y; return end 
    self.flipping, self.facing, pinch.x = "b2f", "front", Y  -- handle back case 
end

end
