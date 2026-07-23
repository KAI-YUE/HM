local ssub = string.sub
local KeySheet = require("core.io.controller_key_sheet")
local ModeSwitch = require("HMEng.controller.debug.mode_switch")
local Y, N = true, false
local DEBUG_PANEL_KEYS = { ["`"] = Y, ["~"] = Y, grave = Y }

return function(Controller)
---------------------------------------------------
-- Key Press Update
---------------------------------------------------
-- Helper: Handle esc
function Controller:_handle_esc() self:emit_intent("escape") end

-- Helper: handle text input
function Controller:_handle_text_input(key)
    local on_keydown, hkeys = self.Fs.on_keydown, self.held_keys
    if     key == "escape"   then self.text_input_hook = nil
    elseif key == "capslock" then self.capslock        = not self.capslock
    else   on_keydown(self, { key = key, caps = hkeys["lshift"] or hkeys["rshift"] }) end
end

--_________________________________________________
-- Main: Handle key press
--_________________________________________________
function Controller:key_press_update(key)
    if self.locks.frame or self.locks.quick_resume then return end
    
    if ssub(key, 1, 2) == "kp" then key = ssub(key, 3) end
    if key == "enter"          then key = "return" end
    if self.text_input_hook    then self:_handle_text_input(key); return end
    if (key == "/" or key == "=" or key == "-" or (key == "s" and self.SET and self.SET.pause and not self.debug_gamepad_mode)) and not _RELEASE_MODE then self:_debug_panel(key); return end
    if self.debug_gamepad_mode and key == "*" and ModeSwitch.cycle_console(self) then return end
    if self.debug_gamepad_mode and KeySheet.map[key] then return end

    if self.UI.title_page_press_any then
        self.frame_buttonpress, self.held_key_times[key] = Y, 0
        self:emit_intent("title_page_press_any")
        return
    end
    if key == "escape"         then self:_handle_esc() end
    if (key == "*" or key == "kp*" or (key == "8" and (self.held_keys.lshift or self.held_keys.rshift))) and not (_RELEASE_MODE or self.debug_gamepad_mode) then self:emit_intent("advance_dialogue_debug") end

    local locked = (self.locked and not self.SET.pause) or self.locks.frame
    if (locked or self.frame_buttonpress) then return end
    self.frame_buttonpress, self.held_key_times[key] = Y, 0

    if key == "delete" and self:activate_secondary_action("delete") then return end
    if _RELEASE_MODE then return end
    self:_debug_panel(key)
end

----------------------------------------------------------
--- Key press & release 
---------------------------------------------------------
function Controller:key_press(k)
    if not (self.debug_gamepad_mode and (KeySheet.map[k] or k == "*" or k == "kp*")) then self:set_HID_flags("keyboard") end
    self.pressed_keys[k], self.held_keys[k] = Y, Y
    local b = self.debug_gamepad_mode and KeySheet.map[k]; if b then self:button_press(b) end
end

function Controller:key_release(k)
    self.held_keys[k], self.released_keys[k] = nil, Y
    local b = self.debug_gamepad_mode and KeySheet.map[k]; if b then self:button_release(b) end
end

----------------------------------------------------------
--- Key hold update 
---------------------------------------------------------
function Controller:key_hold_update(key, dt)
    if (self:_locked() or self.frame_buttonpress) then return end
    local hkt = self.held_key_times;                   if not hkt[key] then return end                 
    if self.debug_gamepad_mode then return end
    if key ~= "r" or self.SET.pause then return end
    if self.debug_field_r_handled then return end
    if hkt[key] <= 0.7 then hkt[key] = hkt[key] + dt; return end 
    hkt[key] = nil
    self:emit_intent("new_run")
end

----------------------------------------------------------
--- Key release update 
---------------------------------------------------------
function Controller:key_release_update(key, dt)
    if key == "r" then self.debug_field_r_handled = nil end
    if self.debug_gamepad_mode and KeySheet.map[key] then return end
    if self:_locked() or self.frame_buttonpress then return end
    self.frame_buttonpress = Y
    if self.debug_gamepad_mode then return end
    if key == "a" and not _RELEASE_MODE then self:emit_intent("revert_debug") end
    if DEBUG_PANEL_KEYS[key]            then self:emit_intent("reset_debug") end
end

end
