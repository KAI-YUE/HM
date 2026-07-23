local Y, N = true, false

local BASE = {
    cancel_ps       = { "b" },
    cancel_xbox     = { "b" },
    confirm_ps      = { "a" },
    confirm_xbox    = { "a" },
    done            = { "y" },
    secondary       = { "x" },
    start           = { "start" },
    scope_field     = { "leftshoulder" },
    scope_hand      = { "rightshoulder" },
}

local DPAD_DIR = { dpup = "U", dpdown = "D", dpleft = "L", dpright = "R" }

local function _playstation(self)       return self.GAMEPAD_CONSOLE == "Playstation" end
local function _contains(list, button)  for _, v in ipairs(list or {}) do if v == button then return Y end end; return N end

return function(Controller)
-----------------------------------------------------
--- Button bindings
----------------------------------------------------- 
function Controller:gamepad_button_bindings()
    self._gamepad_button_bindings = self._gamepad_button_bindings or {}
    return self._gamepad_button_bindings
end

------------------------------------------------------
--- gamepad button action list
------------------------------------------------------
function Controller:gamepad_button_action_list(action)
    local custom = self:gamepad_button_bindings()[action]
    if custom then return custom end
    if action == "confirm" then return _playstation(self) and BASE.confirm_ps or BASE.confirm_xbox end
    if action == "cancel"  then return _playstation(self) and BASE.cancel_ps  or BASE.cancel_xbox  end
    return BASE[action]
end

--------------------------------------------------------
--- gamepad button matches action
--------------------------------------------------------
function Controller:gamepad_button_matches(action, button) return _contains(self:gamepad_button_action_list(action), button) end
function Controller:is_gamepad_confirm_button(button)      return self:gamepad_button_matches("confirm", button) end
function Controller:is_gamepad_cancel_button(button)       return self:gamepad_button_matches("cancel", button) end
function Controller:is_gamepad_secondary_button(button)    return self:gamepad_button_matches("secondary", button) end
function Controller:is_gamepad_start_button(button)        return self:gamepad_button_matches("start", button) end

--------------------------------------------------------
--- gamepad_scope_action
--------------------------------------------------------
function Controller:gamepad_scope_action(button)
    if self:gamepad_button_matches("scope_field", button) then return "field" end
    if self:gamepad_button_matches("scope_hand", button)  then return "hand" end
end

--------------------------------------------------------
--- dpad direction | gamepad_dpad_btn
--------------------------------------------------------
function Controller:gamepad_dpad_dir(button)       return DPAD_DIR[button] end
function Controller:is_gamepad_dpad_button(button) return DPAD_DIR[button] ~= nil end

end
