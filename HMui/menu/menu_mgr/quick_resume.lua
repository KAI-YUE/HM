local SnapshotTrans = require("HMui.menu.transitions.snapshot")

local Y, N = true, false

local quick_resume_wipe_time = 1.6

local M = {}

-------------------------------------------------
--- Quick resume menu
-------------------------------------------------
--- Helper: remove_quick_resume_overlay
local function remove_quick_resume_overlay(gm)
    local gUI = gm.UI
    if not gUI then return Y end
    if gUI.load_slot_confirm then gUI.load_slot_confirm:remove(); gUI.load_slot_confirm = nil end
    if gUI.save_slot_confirm then gUI.save_slot_confirm:remove(); gUI.save_slot_confirm = nil end
    if gUI.delete_slot_confirm then gUI.delete_slot_confirm:remove(); gUI.delete_slot_confirm = nil end
    if gm.clear_modal_backdrop then gm:clear_modal_backdrop() elseif gUI.modal_backdrop then gUI.modal_backdrop = nil end
    gUI.load_slot_confirm_slot_idx, gUI.save_slot_confirm_slot_idx, gUI.delete_slot_confirm_slot_idx = nil, nil, nil
    if gUI.overlay_menu then gUI.overlay_menu:remove(); gUI.overlay_menu = nil end
    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
    return Y
end

--- Helper: unlock_quick_resume_ctrl
local function unlock_quick_resume_ctrl(gm)
    local Ctrl = gm and gm.CTRL;                       if not Ctrl then return Y end
    Ctrl.locks.quick_resume = nil
    return Y
end

--- Helper: lock_quick_resume_ctrl
local function lock_quick_resume_ctrl(gm)
    local Ctrl = gm and gm.CTRL;                       if not Ctrl then return end
    local locks = Ctrl.locks
    locks.frame_set, locks.frame, locks.quick_resume = Y, Y, Y

    if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end
    Ctrl.L_cursor_queue = nil
    for _, key in ipairs({ "cursor_down", "cursor_up", "clicked", "released_on", "dragging", "hovering", "cursor_hover" }) do
        local state = Ctrl[key]
        if state then state.target, state.handled = nil, Y end
    end
    if Ctrl.HID and Ctrl.HID.touch then Ctrl.is_cursor_down = N end
    Ctrl:mod_cursor_context_layer(-1000)
end

---_______________________________
--- main: quick_resume_menu 
---_______________________________
function M.quick_resume_menu(gm)
    local snapshot = SnapshotTrans.capture(gm)
    lock_quick_resume_ctrl(gm)
    remove_quick_resume_overlay(gm)
    gm.SET.pause = N
    SnapshotTrans.wipe_out(gm, snapshot, quick_resume_wipe_time, function() return unlock_quick_resume_ctrl(gm) end)
    if gm.save_settings then gm:save_settings() end
    return Y
end

return M
