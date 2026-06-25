local abs = math.abs

local M = {}

-------------------------------------------
--- helpers
-------------------------------------------
local key_aliases = { lshift = "shift", rshift = "shift", escape = "esc" }

local function _keybind(key)
    local km     = G.keybind_mapping;             if not km then return end
    local alias  = key_aliases[key]
    return km[key] or (alias and km[alias]) or (km[1] and (km[1][key] or (alias and km[1][alias])))
end

local function _debug_gamepad_key(CTRL, key) return not _RELEASE_MODE and CTRL.debug_gamepad_mode and _keybind(key) end
local function _dpad_dir(button) return ({ dpup = "U", dpdown = "D", dpleft = "L", dpright = "R" })[button] end
local function _confirm_cancel(button) return button == "a" or button == "b" end
local function _debug_immediate(button) return _dpad_dir(button) or button == "leftshoulder" or button == "rightshoulder" or button == "start" end

local function _debug_auto_snap(CTRL, button)
    if _confirm_cancel(button) then return end
    if CTRL.focused and CTRL.focused.target and CTRL:is_focusable(CTRL.focused.target) then return end
    local snapped = CTRL:auto_snap_focus()
    local probe = CTRL.debug_gamepad_probe or {}
    CTRL.debug_gamepad_probe = { key = probe.key, button = button, snap = snapped and "snap" or probe.snap or "no snap" }
    if snapped and CTRL.snap_cursor_to then CTRL:_handle_controller() end
end

local function _debug_gamepad_press(CTRL, button)
    CTRL:set_gamepad(CTRL.keyboard_controller)
    CTRL:set_HID_flags("button")
    CTRL:button_press(button)
    _debug_auto_snap(CTRL, button)
    if _debug_immediate(button) then CTRL:button_press_update(button, 0); CTRL.pressed_buttons[button] = nil end
    if CTRL.snap_cursor_to then CTRL:_handle_controller() end
end

-------------------------------------------
--- keyreleased
-------------------------------------------
function M.keyreleased(key)
    local CTRL = G.CTRL
    local button = _debug_gamepad_key(CTRL, key);        if button then CTRL:set_gamepad(CTRL.keyboard_controller); CTRL:set_HID_flags("button"); CTRL:button_release(button); return end
    if CTRL.debug_gamepad_mode then CTRL:key_release(key); return end
    CTRL:set_HID_flags("mouse")
    CTRL:key_release(key)
end

-----------------------------------------
--- key pressed
-----------------------------------------
function M.keypressed(key)
    local CTRL = G.CTRL
    local button = _debug_gamepad_key(CTRL, key);        if button then CTRL.debug_gamepad_probe = { key = key, button = button, snap = "pending" }; _debug_gamepad_press(CTRL, button); return end
    if CTRL.debug_gamepad_mode then CTRL:key_press(key); return end
	CTRL:set_HID_flags("mouse")
	CTRL:key_press(key)
end

-------------------------------------------
--- mouse pressed
-------------------------------------------
function M.mousepressed(x, y, button, touch)
    local CTRL = G.CTRL
    CTRL:set_HID_flags(touch and "touch" or "mouse")
    if button == 1 then CTRL:queue_L_cursor_press(x, y) end
	if button == 2 then CTRL:queue_R_cursor_press(x, y) end
end

--------------------------------------------
--- mousemoved
--------------------------------------------
function M.mousemoved(x, y, dx, dy, istouch)
    local CTRL = G.CTRL
	CTRL.last_touch_time = CTRL.last_touch_time or -1
	if next(love.touch.getTouches()) ~= nil then
		CTRL.last_touch_time = G._T.session_s
	end
    CTRL:set_HID_flags(CTRL.last_touch_time > G._T.session_s - 0.2 and "touch" or "mouse")
end

--------------------------------------------
--- mousereleased
--------------------------------------------
function M.mousereleased(x, y, button) if button == 1 then G.CTRL:L_cursor_release(x, y) end end

--------------------------------------------
--- wheelmoved
--------------------------------------------
function M.wheelmoved(x, y)
    local CTRL = G.CTRL
    CTRL:set_HID_flags("mouse")
    CTRL:queue_scroll(x, y)
end

--------------------------------------------
--- joy stick axis
--------------------------------------------
function M.joystickaxis(joystick, axis, value)
    if abs(value) <= 0.2 or not joystick:isGamepad() then return end
    local CTRL = G.CTRL
    CTRL:set_gamepad(joystick)
    CTRL:set_HID_flags("axis")
end

-------------------------------------------
--- gamepad pressed
-------------------------------------------
function M.gamepadpressed(joystick, button)
	button = G.button_mapping[button] or button
    local CTRL = G.CTRL
	CTRL:set_gamepad(joystick)
    CTRL:set_HID_flags("button", button)
    CTRL:button_press(button)
end

-------------------------------------------
--- gamepad released
-------------------------------------------
function M.gamepadreleased(joystick, button)
	button = G.button_mapping[button] or button
    local CTRL = G.CTRL
    CTRL:set_gamepad(joystick)
    CTRL:set_HID_flags("button", button)
    CTRL:button_release(button)
end

return M
