local C, CUtils        = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local HMPanel          = require("HMEng.ui_actors.hm_panel")
local TabUtils         = require("HMfns.utils.table_utils")
local PauseMenuData    = require("HMui.menu.data.pages._0_pause_menu_page")
local Transitions      = require("HMfns.animate.transitions.menu_transitions")
local SettingsConfirm  = require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm")
local ConfirmPopup     = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")

local copy = TabUtils.deep_copy
local tint_with_alpha = CUtils.tint_with_alpha

local pause_underlay_dim = tint_with_alpha(C.STEEL, 0.4)
local Y, N = true, false

local M = {}

-------------------------------------------------
--- Helper: clear_title_options_locks
-------------------------------------------------
local function clear_title_options_locks(Ctrl)
    local locks = Ctrl and Ctrl.locks;                   if not locks then return end
    locks.title_page_options, locks.stroked_page_child_control = nil, nil
end

-------------------------------------------------
--- Open pause (escape) menu
-------------------------------------------------
--- Helper: _escape_split_T
local function _escape_split_T(gm) local RT = gm._room.T; return { x = RT.x, y = RT.y, w = RT.w, h = RT.h } end

function M.open_pause_menu(gm)
    local gUI      = gm.UI
    local OM, Ctrl = gUI.overlay_menu, gm.CTRL
    
    local replacing = (not not OM);                     if OM then OM:remove() end
    local Cl        = Ctrl.locks

    clear_title_options_locks(Ctrl)
    Cl.frame_set, Cl.frame, Ctrl.cursor_down.target = Y, Y, nil
    Ctrl:mod_cursor_context_layer((gm.fix_cursor_stack or replacing) and 0 or 1)

    gm.SET.pause = Y
    local args   = copy(PauseMenuData)

    args.T,              args.fit_axis      = _escape_split_T(gm), "width"
    args.type,           args.can_collide   = "overlay_menu",      Y
    args.can_hover,      args.hit_area      = Y,                   "world"
    args.can_click,      args.can_drag      = N,                   N
    args.fx_mask_shader, args.fx_mask_ref   = "_-1_page_wipe",    "room"

    gUI.overlay_menu = HMPanel(gm, args)
    OM = gUI.overlay_menu

    OM.config  = OM.config or {}
    local _cfg = OM.config

    _cfg.no_esc,                  _cfg.underlay              = N,           "snapshot"
    _cfg.underlay_shader,         _cfg.underlay_blur_radius  = "mc_polar",  5.
    _cfg.underlay_flow_strength,  _cfg.underlay_shader_time  = 1.0,         gm._T.real_s or 0
    
    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
    _cfg.underlay_dim_color = pause_underlay_dim

    if not gm._suppress_pause_open_transition then Transitions.open_pause_menu(gm, OM) end
end

-------------------------------------------------
--- Handle escape menu trigger
-------------------------------------------------
function M.handle_escape(gm)
    local gUI, ST   = gm.UI,            gm.g_state
    local OM,  STS  = gUI.overlay_menu, gm.g_states
    if gm.CTRL.locks and gm.CTRL.locks.quick_resume then return end
    if ConfirmPopup.cancel_active_popup(gm)         then return end
    if gUI.delete_slot_confirm then return require("HMui.menu.data.pages._1_load_2_save_pages._shared.delete_confirm").confirm_delete_slot_no(gm) end
    if gUI.title_page_options  then return require("HMui.menu.menu_mgr").title_page_options_back(gm) end

    if     ST == STS.splash     then gm:delete_run(); gm:title_page()
    elseif not OM               then M.open_pause_menu(gm)
    elseif not OM.config.no_esc then
        local close_action = function(_gm) return require("HMui.menu.menu_mgr").close_menu(_gm) end
        if SettingsConfirm.open_system_settings_confirm_if_changed(gm, { no_action = close_action, yes_action = close_action }) then return end
        require("HMui.menu.menu_mgr").close_menu(gm)
    end
end

-------------------------------------------------
--- Close menu
-------------------------------------------------
function M.close_menu(gm)
    local OM    = gm.UI.overlay_menu;                      if not OM then return end
    local Ctrl  = gm.CTRL;                                 local Ctlock = Ctrl.locks
    Ctlock.frame_set, Ctlock.frame = Y, Y;                 Ctrl:mod_cursor_context_layer(-1000)
    OM:remove();                                           gm.UI.overlay_menu = nil

    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
    gm.SET.pause = N;                                      gm:save_settings()
end

return M
