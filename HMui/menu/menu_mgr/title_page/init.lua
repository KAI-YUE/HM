local FileIO           = require("core.io.fileio")
local Common           = require("HMui.menu.menu_mgr.title_page.common")
local Launch           = require("HMui.menu.menu_mgr.title_page.launch")
local Options          = require("HMui.menu.menu_mgr.title_page.options")
local Timeline         = require("HMui.menu.data.pages._-1_title_page.anims.timeline")
local TunnelColors     = require("HMui.menu.transitions.data.page_tunnel_colors")
local RunTransition    = require("HMui.menu.transitions.run")
local Wallpaper        = require("HMui.menu.menu_mgr.title_page.wallpaper")
local TitlePageData    = require("HMui.menu.data.pages._-1_title_page.init")
local SettingsConfirm  = require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm")
local LFS              = love.filesystem

local _Finfo    = LFS.getInfo
local _unpickle = FileIO.unpickle
local _tn_game  = TunnelColors.title_new_game

local Y, N = true, false

local M = {}

-------------------------------------------------
--- launch_title_page
-------------------------------------------------
function M.launch_title_page(gm, state) return Launch.launch_title_page(gm, state) end

-------------------------------------------------
--- title_page_can_continue
-------------------------------------------------
function M.title_page_can_continue(gm)
    local save_path = Common.title_page_save_path(gm)
    local savefile  = _Finfo(save_path) or _Finfo((gm.SET.profile or 1) .. "/save.hm")
    return savefile ~= nil
end

-------------------------------------------------
--- title_page_press_any
-------------------------------------------------
function M.title_page_press_any(gm)
    if not (gm.UI and gm.UI.title_page_press_any) then return end
    gm.UI.title_page_press_any = nil
    Wallpaper.fade_out_blur(gm)
    Common.title_page_switch_page(gm, TitlePageData(gm, "title"), "new_game", { delay = Timeline.stage2.switch_fade, focus_delay = Timeline.stage2.focus_delay, child_control_lock_delay = Timeline.stage2.control_lock_delay })
    return Y
end

-------------------------------------------------
--- title_page_back_to_preparation
-------------------------------------------------
function M.title_page_back_to_preparation(gm)
    if not (gm.UI and gm.UI.title_page_panel) or gm.UI.title_page_press_any then return end
    gm.UI.title_page_press_any = Y
    Wallpaper.spawn_blur(gm)
    Common.title_page_switch_page(gm, TitlePageData(gm, "preparation"), "press_any", { delay = 0.55, focus_delay = 0.60, child_control_lock_delay = 0.62 })
    return Y
end

-------------------------------------------------
--- title_page_new_games
-------------------------------------------------
function M.title_page_new_game(gm)
    return RunTransition.start(gm, {
        kind = "page",
        transition = {
            tunnel_tone_light  = _tn_game.tunnel_tone_light,
            tunnel_tone_mid    = _tn_game.tunnel_tone_mid,
            tunnel_tone_accent = _tn_game.tunnel_tone_accent,
        },
        run_args = function(_gm)
            _gm.SET.current_setup = "New Run"
            return _gm.Fs.new_run_args(_gm, { field_spawn_batch_size = 8, field_spawn_batch_delay = 1/60 })
        end,
    })
end

--------------------------------------------------
--- title_page_continue
--------------------------------------------------
function M.title_page_continue(gm)
    local SET           = gm.SET
    local save_path     = Common.title_page_save_path(gm)
    local slot_data     = _unpickle(save_path) or _unpickle((SET.profile or 1) .. "/save.hm")
    local run_snapshot  = slot_data and (slot_data.run or slot_data);       if not run_snapshot then return end
    
    gm.saved_game      = run_snapshot
    SET.current_setup  = "Continue"
    return RunTransition.start(gm, {
        kind = "page",
        transition = {
            tunnel_tone_light  = _tn_game.tunnel_tone_light,
            tunnel_tone_mid    = _tn_game.tunnel_tone_mid,
            tunnel_tone_accent = _tn_game.tunnel_tone_accent,
        },
        run_args = { savetext = run_snapshot, save_data = slot_data },
    })
end

----------------------------------------------------
--- title_page_options
---------------------------------------------------- 
function M.title_page_options(gm) return Options.title_page_options(gm) end

----------------------------------------------------
--- title_page_options_back
---------------------------------------------------- 
function M.title_page_options_back(gm)
    if SettingsConfirm.open_system_settings_confirm_if_changed(gm, { no_action = M.title_page_options_back, yes_action = M.title_page_options_back }) then return Y end
    Options.clear_title_page_options_transition_ctrl(gm)
    
    gm.UI.title_page_options,                   gm.title_page_options_snapshot_blur_radius  = nil, nil
    gm.title_page_options_snapshot,             gm.title_page_options_snapshot_shader       = nil, nil
    gm.title_page_options_snapshot_dim_color,   gm.title_page_options_snapshot_shader_time  = nil, nil
    
    Common.title_page_replace_panel(gm, TitlePageData(gm, "title"), N)
    Common.title_page_snap_to(gm, "options")
    return Y
end

----------------------------------------------------
--- title_page_
---------------------------------------------------- 
function M.title_page_quit(gm) return gm.Fs.qui(gm) end

return M
