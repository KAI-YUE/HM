local UI            = require("HMui.menu.data.pages._1_load_2_save_pages._1_load.load_confirm.ui_helpers")
local RunTransition = require("HMui.menu.transitions.run")

local M = {}

local Y, N = true, false

local load_wipe_time = 1.58

------------------------------------
--- cancel_confirm
------------------------------------
--- Helper: schedule_confirm_ctrl_lock
local function schedule_confirm_ctrl_lock(gm, delay)
    local Ctrl   = gm and gm.CTRL;                       if not Ctrl then return end
    local locks  = Ctrl.locks;                           local had_frame = locks.frame
    locks.frame, locks.load_slot_confirm = Y, Y;         if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end

    local EM, delay = gm.E_MANAGER, delay or 0.18
    EM:enqueue_event({ queue = "load_slot_confirm", trigger = "after", delay = delay, blockable = N, blocking = N, no_delete = Y,
        func = function() locks.load_slot_confirm = nil; if not had_frame and locks.frame and not locks.frame_set then locks.frame = nil end; return Y; end })
end

---_________________________________
--- main: cancel_confirm
---_________________________________
function M.cancel_confirm(gm) schedule_confirm_ctrl_lock(gm); UI.remove_popup(gm) end

--- Helper: clear_load_overlay
local function clear_load_overlay(gm)
    local gUI = gm.UI
    if not gUI then return Y end
    if gm.clear_modal_backdrop then gm:clear_modal_backdrop(gUI.load_slot_confirm)
    elseif gUI.modal_backdrop and gUI.modal_backdrop.owner == gUI.load_slot_confirm then gUI.modal_backdrop = nil end
    if gUI.load_slot_confirm then gUI.load_slot_confirm:remove(); gUI.load_slot_confirm = nil end
    gm.load_transition_snapshot = nil
    gUI.load_slot_confirm_slot_idx = nil
    if gUI.overlay_menu then gUI.overlay_menu:remove(); gUI.overlay_menu = nil end
    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
    return Y
end

--- Helper: begin_load_slot_transition
local function begin_load_slot_transition(gm, args)
    gm.SET.pause = Y
    return RunTransition.start(gm, {
        kind = "snapshot",
        duration = load_wipe_time,
        run_args = args,
        on_revealed = function() return clear_load_overlay(gm) end,
    })
end

-----------------------------------
--- confirm_load_slot
-----------------------------------
function M.confirm_load_slot(gm, slot_idx)
    slot_idx = tonumber(slot_idx) or 1
    local slot_data    = gm.load_save_slot and gm:load_save_slot(slot_idx)
    local run_snapshot = slot_data and (slot_data.run or slot_data)
    if not run_snapshot then UI.remove_popup(gm); return end

    gm.SET.slot_idx = slot_idx
    return begin_load_slot_transition(gm, { savetext = run_snapshot, save_data = slot_data })
end

return M
