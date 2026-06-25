local UI            = require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm.ui_helpers")
local Gate          = require("HMEng.controller.input_gate")
local ControlState  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local VideoSettings = require("HMfns.systems.video_settings")
local Tabs          = require("HMui.menu.data.pages._3_opt_menu_page.tabs")
local ChildAnims    = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets")
local SnapshotTrans = require("HMui.menu.transitions.snapshot")
local TabUtils      = require("HMfns.utils.table_utils")
local SeedLists     = require("HMui.menu.data.pages._3_opt_menu_page.sampling_seed_lists")

local random_pick = TabUtils.random_pick

local T_sts = { "cursor_down", "cursor_up", "clicked", "released_on", "dragging", "hovering", "cursor_hover" }
local _lang_refresh_wipe_time = 0.62

local Y, N = true, false

local M = {}

--- Helper: schedule_confirm_ctrl_lock
local function schedule_confirm_ctrl_lock(gm, delay)
    local Ctrl = gm and gm.CTRL;                       if not Ctrl then return end
    local locks = Ctrl.locks;                          local had_frame = locks.frame
    locks.frame, locks.system_settings_confirm = Y, Y
    Ctrl.L_cursor_queue = nil

    for _, key in ipairs(T_sts) do local state = Ctrl[key]; if state then state.target, state.handled = nil, Y end end
    if Ctrl.HID and Ctrl.HID.touch then Ctrl.is_cursor_down = N end

    local EM, delay = gm.E_MANAGER, delay or 0.18
    EM:enqueue_event({ queue = "system_settings_confirm", trigger = "after", delay = delay, blockable = N, blocking = N, no_delete = Y,
        func = function() locks.system_settings_confirm = nil; if not had_frame and locks.frame and not locks.frame_set then locks.frame = nil end; return Y end })
end

--- Helper: clamp_text_speed
local function clamp_text_speed(value)
    value = math.floor((tonumber(value) or 3) + 0.5)
    if value < 1 then return 1 end
    if value > 5 then return 5 end
    return value
end

--- Helper: restore_preview_side_effect
local function restore_preview_side_effect(gm, key)
    local SET = gm.SET

    if key == "language" and gm.set_language then gm:set_language() end
    if key == "vsync" and SET.s_win then
        if love.window.setVSync then love.window.setVSync(SET.s_win.vsync or 1); return end
        VideoSettings.apply_window_settings(gm, { queued_c = gm.SET.s_win }, true)
    end
    if (key == "screenmode" or key == "screenres") and SET.s_win then VideoSettings.apply_window_settings(gm, { queued_c = gm.SET.s_win }, true) end
end

--- Helper: clear_resolution_preview_memory
local function clear_resolution_preview_memory(gm) gm.option_menu_resolution_preview_base_res = nil end

--- Helper: clamp_game_speed
local function clamp_game_speed(value)
    value = math.floor((tonumber(value) or 4) + 0.5)
    if value < 1 then return 1 end
    if value > 5 then return 5 end
    return value
end

--- Helper: clamp_audio_value
local function clamp_audio_value(value, fallback)
    value = math.floor((tonumber(value) or fallback or 0) + 0.5)
    if value < 0 then return 0 end
    if value > 100 then return 100 end
    return value
end

--- Helper: clamp_audio_settings
local function clamp_audio_settings(SET, pending)
    local snd = SET and SET.s_snd
    if not (snd and pending and pending.s_snd) then return end
    if pending.s_snd.volume       ~= nil then snd.volume       = clamp_audio_value(snd.volume, 100) end
    if pending.s_snd.music_volume ~= nil then snd.music_volume = clamp_audio_value(snd.music_volume, 5) end
    if pending.s_snd.SE_volume    ~= nil then snd.SE_volume    = clamp_audio_value(snd.SE_volume, 30) end
    if pending.s_snd.voice_volume ~= nil then snd.voice_volume = clamp_audio_value(snd.voice_volume, 50) end
    if pending.s_snd.dialogue_voice ~= nil then snd.dialogue_voice = not not snd.dialogue_voice end
end

--- Helper: clamp_fps_cap
local function clamp_fps_cap(value)
    if value == "auto" then return "auto", 500 end
    value = math.floor((tonumber(value) or 500) + 0.5)
    if value < 30 then return 30 end
    if value > 500 then return 500 end
    return value
end

--- Helper: apply_video_settings
local function apply_video_settings(gm, pending)
    if pending.fps_cap ~= nil then local cap, runtime_cap = clamp_fps_cap(gm.SET.fps_cap); gm.SET.fps_cap, gm.FPS_CAP = cap, runtime_cap or cap end
    if pending.queued_c then VideoSettings.apply_window_settings(gm, pending) end
end

--- Helper: has_window_settings
local function has_window_settings(pending) return pending and pending.queued_c and next(pending.queued_c) ~= nil end

--- Helper: option_panel
local function option_panel(gm)
    local panel = gm and gm.UI and gm.UI.overlay_menu
    local widget = panel and panel.widget
    if widget and widget.config and widget.config.renderer == "stroked_page" then return panel, widget end
end

--- Helper: refresh_option_children
local function refresh_option_children(gm)
    local panel, widget = option_panel(gm);                      if not panel then return end
    local state = panel.opt_tab_state or gm.opt_menu_tab_state or Tabs.default_state()
    panel.opt_tab_state, gm.opt_menu_tab_state = state, state
    local token = (panel.stroked_page_switch_token or 0) + 1
    panel.stroked_page_switch_token = token
    ChildAnims.replace_now(panel, widget, gm, Tabs.selected_child_widgets(state, gm), token)
end

--- Helper: language_refresh_snapshot
local function language_refresh_snapshot(gm, pending)
    if not (pending and pending.language ~= nil) then return end
    return SnapshotTrans.capture(gm, { fx_mask_seed = random_pick(SeedLists.tabs.opt_system), snapshot_shader = "mc", snapshot_blur_radius = 5. })
end

--- Helper: apply_pending_settings
local function apply_pending_settings(gm)
    local pending, SET = gm.opt_system_pending or {}, gm.SET
    if pending.text_speed ~= nil then SET.text_speed = clamp_text_speed(SET.text_speed) end
    if pending.g_speed    ~= nil then SET.g_speed = clamp_game_speed(SET.g_speed) end
    clamp_audio_settings(SET, pending)
    apply_video_settings(gm, pending)
    if pending.language   ~= nil and gm.set_language then gm:set_language(); refresh_option_children(gm) end
    VideoSettings.invalidate_card_front_canvases(gm)
    ControlState.apply_preview(gm)
end

--- Helper: pop_no_action
local function pop_no_action(gm)
    local action = gm and gm.opt_system_confirm_no_action
    if gm then gm.opt_system_confirm_no_action = nil end
    return action
end

--- Helper: pop_yes_action
local function pop_yes_action(gm)
    local action = gm and gm.opt_system_confirm_yes_action
    if gm then gm.opt_system_confirm_yes_action = nil end
    return action
end

--- Helper: defer_yes_action
local function defer_yes_action(gm, yes_action)
    if not (gm and gm.E_MANAGER and yes_action) then return end
    local EM = gm.E_MANAGER
    EM:enqueue_event({ queue = "system_settings_confirm", trigger = "after", delay = EM.queue_dt or (1/60), blockable = N, blocking = N, no_delete = Y,
        func = function() yes_action(gm); return Y end })
    return Y
end

--- Helper: discard_settings
function M.discard_settings(gm)
    ControlState.cancel_preview(gm, { on_restore = restore_preview_side_effect })
    clear_resolution_preview_memory(gm)
end

------------------------------------
--- cancel_confirm
------------------------------------
function M.cancel_confirm(gm)
    local no_action = pop_no_action(gm)
    pop_yes_action(gm)
    schedule_confirm_ctrl_lock(gm)
    UI.remove_popup(gm)
    if no_action then M.discard_settings(gm); return no_action(gm) end
end

-----------------------------------
--- confirm_settings
-----------------------------------
function M.confirm_settings(gm)
    local yes_action = pop_yes_action(gm)
    pop_no_action(gm)

    local had_window_settings = has_window_settings(gm.opt_system_pending)
    local snapshot            = language_refresh_snapshot(gm, gm.opt_system_pending)
    
    Gate.suspend_interaction(gm)
    schedule_confirm_ctrl_lock(gm, 0.5)
    UI.remove_popup(gm)
    apply_pending_settings(gm)
    clear_resolution_preview_memory(gm)
    
    if snapshot         then SnapshotTrans.wipe_out(gm, snapshot, _lang_refresh_wipe_time) end
    if gm.save_settings then gm:save_settings(Y) end
    if had_window_settings and yes_action then return defer_yes_action(gm, yes_action) end
    if yes_action then return yes_action(gm) end
end

return M
