local UI          = require("HMui.menu.data.pages._1_load_2_save_pages._shared.delete_confirm.ui_helpers")
local SlotRefresh = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.refresh")
local Gate        = require("HMEng.controller.input_gate")

local Y, N = true, false

local M = {}

--------------------------------------------------
--- Helper: schedule confirmation controller lock
--------------------------------------------------
local function schedule_confirm_ctrl_lock(gm, delay)
    local Ctrl = gm and gm.CTRL;                         if not Ctrl then return end
    local locks, had_frame = Ctrl.locks, Ctrl.locks.frame
    locks.frame, locks.delete_slot_confirm = Y, Y
    Ctrl.L_cursor_queue = nil

    for _, key in ipairs({ "cursor_down", "cursor_up", "clicked", "released_on", "dragging", "hovering", "cursor_hover" }) do
        local state = Ctrl[key]
        if state then state.target, state.handled = nil, Y end
    end
    if Ctrl.HID and Ctrl.HID.touch then Ctrl.is_cursor_down = N end

    gm.E_MANAGER:enqueue_event({ queue = "delete_slot_confirm", trigger = "after", delay = delay or 0.18, blockable = N, blocking = N, no_delete = Y,
        func = function() locks.delete_slot_confirm = nil; if not had_frame and locks.frame and not locks.frame_set then locks.frame = nil end; return Y end })
end

--------------------------------------------------
--- Main: cancel confirmation
--------------------------------------------------
function M.cancel_confirm(gm)
    schedule_confirm_ctrl_lock(gm)
    UI.remove_popup(gm)
end

--------------------------------------------------
--- Main: delete slot
--------------------------------------------------
function M.confirm_delete_slot(gm, slot_idx)
    slot_idx = tonumber(slot_idx) or 1
    Gate.suspend_interaction(gm)
    schedule_confirm_ctrl_lock(gm, 0.5)
    UI.remove_popup(gm)

    if not gm.delete_save_slot then return end
    local empty_meta = gm:delete_save_slot(slot_idx)
    SlotRefresh.refresh(gm, slot_idx, empty_meta)
    return Y
end

return M
