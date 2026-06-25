local Y, N = true, false

local M = {}

--------------------------------------------------
--- Helper: enable synthetic gamepad mode
--------------------------------------------------
local function enable_gamepad_mode(ctrl)
    ctrl.debug_gamepad_mode = Y
    ctrl:set_gamepad(ctrl.keyboard_controller)
    ctrl.GAMEPAD_CONSOLE = "Playstation"
    ctrl:set_HID_flags("button")
end

--------------------------------------------------
--- Helper: disable synthetic gamepad mode
--------------------------------------------------
local function disable_gamepad_mode(ctrl)
    ctrl.debug_gamepad_mode = N
    ctrl:set_HID_flags("mouse")
end

--------------------------------------------------
--- Main: toggle synthetic gamepad mode
--------------------------------------------------
function M.handle(ctrl, key)
    if key ~= "/" then return end
    if ctrl.debug_gamepad_mode then disable_gamepad_mode(ctrl) else enable_gamepad_mode(ctrl) end
    return Y
end

return M
