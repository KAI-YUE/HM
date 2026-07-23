local PauseMenuData   = require("HMui.menu.data.pages._0_pause_menu_page")
local LoadMenuData    = require("HMui.menu.data.pages._1_load_2_save_pages._1_load")
local SaveMenuData    = require("HMui.menu.data.pages._1_load_2_save_pages._2_save")
local OptMenuData     = require("HMui.menu.data.pages._3_opt_menu_page")
local SnapshotTrans   = require("HMui.menu.transitions.snapshot")
local SeedLists       = require("HMui.menu.transitions.seed_lists")
local TabUtils        = require("HMfns.utils.table_utils")
local SettingsConfirm = require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm")
local ChildFadeTree   = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")

local random_pick = TabUtils.random_pick

local Y, N = true, false

local options2pause_wipe_time   = 1.6
local options2pause_alpha_time  = 0.42

local M = {}

local SwitchPageData = {
    pause2load_menu     = LoadMenuData,     load2pause_menu     = PauseMenuData,
    pause2save_menu     = SaveMenuData,     save2pause_menu     = PauseMenuData,
    pause2options_menu  = OptMenuData,      --- options2pause is defined at the end 
}

---------------------------------------------
--- options2pause_menu
---------------------------------------------
--- Helper: _stroked_overlay
local function _stroked_overlay(gm)
    local OM = gm.UI.overlay_menu;            if not OM or not OM.switch_stroked_page   then return end
    local _widget = OM.widget;                if not _widget then return end 
    local _cfg    = _widget.config;           if not _cfg    then return end 
    if _cfg.renderer == "stroked_page" then return OM end
end

--- Helper: resolve_page_data | switch stroked page | 
local function resolve_page_data(page_data, gm)  if type(page_data) == "function" then return page_data(gm) end; return page_data end
local function _switch_stroked_page(page_data) return function(gm) local OM = _stroked_overlay(gm); if OM then return OM:switch_stroked_page(resolve_page_data(page_data, gm)) end end end

for name, page_data in pairs(SwitchPageData) do M[name] = _switch_stroked_page(page_data) end

--- Helper: clear pause hints before switching
local function _pause_hint_switch(page_data)
    return function(gm)
        local OM = _stroked_overlay(gm);                 if not OM then return end
        local widget = OM.widget
        for _, child in ipairs((widget and widget.page_child_widgets) or {}) do
            if child.config and child.config.renderer == "hint_btn" then child.disable_button = Y; ChildFadeTree.set_tree_alpha(child, 0) end
        end
        return OM:switch_stroked_page(resolve_page_data(page_data, gm))
    end
end

M.pause2load_menu    = _pause_hint_switch(LoadMenuData)
M.pause2save_menu    = _pause_hint_switch(SaveMenuData)
M.pause2options_menu = _pause_hint_switch(OptMenuData)

--- Helper: clear_enter_queues
local function clear_enter_queues(gm, queues)
    local EM = gm and gm.E_MANAGER;                  if not EM then return end
    for _, queue in ipairs(queues or {}) do EM:clear_queue(queue) end
end

--- Helper: switch_pause_after_enter_clear
local function switch_pause_after_enter_clear(queues)
    return function(gm)
        clear_enter_queues(gm, queues)
        local OM = _stroked_overlay(gm);             if OM then return OM:switch_stroked_page(resolve_page_data(PauseMenuData, gm)) end
    end
end

--- main: load/save to pause
M.load2pause_menu = switch_pause_after_enter_clear({ "load_menu_enter", "save_menu_enter" })
M.save2pause_menu = switch_pause_after_enter_clear({ "save_menu_enter" })

--- Helper: remove_options_overlay
local function remove_options_overlay(gm)
    local gUI = gm.UI;                              if not gUI then return Y end
    if gm.clear_modal_backdrop then gm:clear_modal_backdrop() elseif gUI.modal_backdrop then gUI.modal_backdrop = nil end
    if gUI.system_settings_confirm then gUI.system_settings_confirm:remove(); gUI.system_settings_confirm = nil end
    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
    return Y
end

--- Helper: lock_options2pause_ctrl
local function lock_options2pause_ctrl(gm)
    local Ctrl = gm and gm.CTRL;                    if not Ctrl then return end
    local locks = Ctrl.locks
    locks.frame_set, locks.frame, locks.options2pause = Y, Y, Y
    if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end
end

--- Helper: unlock_options2pause_ctrl
local function unlock_options2pause_ctrl(gm)
    local Ctrl = gm.CTRL;                    if not Ctrl then return Y end
    Ctrl.locks.options2pause = nil;          return Y
end

---_________________________________________
--- main: options2pause_menu
---_________________________________________
function M.options2pause_menu(gm)
    local OM = _stroked_overlay(gm);                if not OM or OM.options2pause_wiping then return end
    if SettingsConfirm.open_system_settings_confirm_if_changed(gm, { no_action = M.options2pause_menu, yes_action = M.options2pause_menu }) then return Y end
    OM.options2pause_wiping = Y

    local snapshot = SnapshotTrans.capture(gm, { fx_mask_seed = random_pick(SeedLists.options2pause_page_wipe) })
    lock_options2pause_ctrl(gm)
    remove_options_overlay(gm)
    SettingsConfirm.discard_settings(gm)
    SnapshotTrans.open_pause_under_snapshot(gm, options2pause_alpha_time)
    return SnapshotTrans.wipe_out(gm, snapshot, options2pause_wipe_time, function() return unlock_options2pause_ctrl(gm) end)
end

return M
