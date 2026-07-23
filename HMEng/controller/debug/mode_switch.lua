local Y, N = true, false

local M = {}
local CONSOLES = { "Playstation", "Xbox", "Generic", "Nintendo", "SteamDeck" }

--------------------------------------------------
--- Helper: is toggle key
--------------------------------------------------
local function is_toggle_key(ctrl, key) return key == "/" or (key == "s" and ctrl.SET and ctrl.SET.pause and not ctrl.debug_gamepad_mode) end

--------------------------------------------------
--- Helper: enable synthetic gamepad mode
--------------------------------------------------
local function enable_gamepad_mode(ctrl)
    ctrl.debug_gamepad_mode = Y
    ctrl.debug_gamepad_console_i = ctrl.debug_gamepad_console_i or 1
    ctrl:set_gamepad(ctrl.keyboard_controller)
    ctrl.GAMEPAD_CONSOLE = CONSOLES[ctrl.debug_gamepad_console_i] or "Playstation"
    ctrl:set_HID_flags("button")
end

--------------------------------------------------
--- Helper: disable synthetic gamepad mode
--------------------------------------------------
local function disable_gamepad_mode(ctrl)
    ctrl.debug_gamepad_mode = N
    ctrl:set_gamepad(nil)
    ctrl:set_HID_flags("keyboard")
    ctrl.HID.controller, ctrl.HID.dpad, ctrl.HID.axis_cursor = N, N, N
    love.mouse.setVisible(Y)
end

--------------------------------------------------
--- Main: toggle synthetic gamepad mode
--------------------------------------------------
function M.handle(ctrl, key)
    if not is_toggle_key(ctrl, key) then return end
    if ctrl.debug_gamepad_mode then disable_gamepad_mode(ctrl) else enable_gamepad_mode(ctrl) end
    return Y
end

--------------------------------------------------
--- Main: cycle synthetic console
--------------------------------------------------
function M.cycle_console(ctrl)
    if not (ctrl and ctrl.debug_gamepad_mode) then return end
    ctrl.debug_gamepad_console_i = ((ctrl.debug_gamepad_console_i or 1) % #CONSOLES) + 1
    ctrl.GAMEPAD_CONSOLE = CONSOLES[ctrl.debug_gamepad_console_i]
    ctrl.debug_gamepad_probe = { console = ctrl.GAMEPAD_CONSOLE }
    ctrl:set_HID_flags("button")
    return Y
end

return M
