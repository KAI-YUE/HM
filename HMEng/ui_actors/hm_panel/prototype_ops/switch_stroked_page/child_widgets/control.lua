local Y, N = true, false

local M = {}
local T_cursor_states = { "cursor_down", "cursor_up", "clicked", "released_on", "dragging", "hovering", "cursor_hover" }

-----------------------------
--- switch stroked_page child widget controller locking helpers
----------------------------------
--- Helper: clear_controller_targets
local function _clear_controller_targets(Ctrl)
    Ctrl.L_cursor_queue = nil
    for _, key in ipairs(T_cursor_states) do
        local state = Ctrl[key]
        if state then state.target, state.handled = nil, Y end
    end
    if Ctrl.HID and Ctrl.HID.touch then Ctrl.is_cursor_down = N end
end

function M.lock(gm, token)
    local Ctrl = gm and gm.CTRL
    if not Ctrl then return end
    Ctrl.locks.stroked_page_child_control = token or Y
    _clear_controller_targets(Ctrl)
end

function M.unlock(gm, token)
    local Ctrl = gm and gm.CTRL
    if not (Ctrl and Ctrl.locks) then return Y end
    if token and Ctrl.locks.stroked_page_child_control ~= token then return Y end
    Ctrl.locks.stroked_page_child_control = nil
    return Y
end

return M
