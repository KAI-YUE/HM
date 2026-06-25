local UI   = require("HMui.menu.data.pages._1_load_2_save_pages._2_save.save_confirm.ui_helpers")
local Gate = require("HMEng.controller.input_gate")

local Y, N = true, false

local M = {}

------------------------------------
--- cancel_confirm
------------------------------------
--- Helper: schedule_confirm_ctrl_lock
local function schedule_confirm_ctrl_lock(gm, delay)
    local Ctrl   = gm and gm.CTRL;                       if not Ctrl then return end
    local locks  = Ctrl.locks;                           local had_frame = locks.frame
    locks.frame, locks.save_slot_confirm = Y, Y
    Ctrl.L_cursor_queue = nil
    for _, key in ipairs({ "cursor_down", "cursor_up", "clicked", "released_on", "dragging", "hovering", "cursor_hover" }) do
        local state = Ctrl[key]
        if state then state.target, state.handled = nil, Y end
    end
    if Ctrl.HID and Ctrl.HID.touch then Ctrl.is_cursor_down = N end

    local EM, delay = gm.E_MANAGER, delay or 0.18;
    EM:enqueue_event({ queue = "save_slot_confirm", trigger = "after", delay = delay, blockable = N, blocking = N, no_delete = Y,
        func = function() locks.save_slot_confirm = nil; if not had_frame and locks.frame and not locks.frame_set then locks.frame = nil end; return Y; end })
end

---_________________________________
--- main: cancel_confirm
---_________________________________
function M.cancel_confirm(gm) if gm.clear_prepared_save_slot_data then gm:clear_prepared_save_slot_data() end; schedule_confirm_ctrl_lock(gm); UI.remove_popup(gm) end

-----------------------------------
--- confirm_save_slot
-----------------------------------
function M.confirm_save_slot(gm, slot_idx)
    Gate.suspend_interaction(gm)
    schedule_confirm_ctrl_lock(gm, 0.5)
    UI.remove_popup(gm)
    
    if not gm.save_slot then return end
    local saved_data = gm:save_slot(slot_idx)
    UI.refresh_save_slot_ui(gm, slot_idx, saved_data)
end

return M
