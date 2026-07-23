
local Menu      = require("HMui.menu.menu_mgr")
local TabSwitch = require("HMui.menu.data.pages._3_opt_menu_page.tabs.tab_ops.tab_switch")

local controller_intents = {
    escape                = Menu.handle_escape,
    exit_to_title_page    = function(gm) gm:delete_run(); gm:title_page() end,
    menu_options          = Menu.open_options,
    opt_tab_step          = function(gm, payload) return TabSwitch.opt_tab_step(gm, payload and payload.step or 1) end,
    opt_back              = function(gm) return require("HMui.menu.menu_switch").options2pause_menu(gm) end,
    opt_done              = function(gm) return require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm").open_system_settings_confirm_if_changed(gm) end,

    title_page_press_any            = Menu.title_page_press_any,
    title_page_back_to_preparation  = Menu.title_page_back_to_preparation,
    
    exit_overlay   = Menu.close_menu,
    vibrate        = function(gm) gm._vibr = gm._vibr + 0.7 end,
    new_run        = function(gm) gm:_new_run() end,
    revert_debug   = function(gm) gm.debug.on = not gm.debug.on end,
    reset_debug    = function(gm) gm:_reset_debug() end,
    toggle_debug   = function(gm) gm:_toggle_debug() end,
    revert_toggle  = function(gm) gm.debug_UI_toggle = not gm.debug_UI_toggle end,
    load_data      = function(gm) gm:_dt_load() end,
    profile_game   = function(gm) gm:_profile_game() end,
    revert_perf    = function(gm) gm.SET.perf_mode = not gm.SET.perf_mode end,
    debug_hud_mod  = function(gm, payload) if payload then gm:_debug_hud_mod(payload.stat, payload.delta or 0) end end,
    debug_lang_step = function(gm, payload) return gm:_debug_language_step(payload and payload.step or 1) end,
    
    debug_hud_toggle_foe = function(gm) gm:_debug_hud_toggle_foe() end,
    advance_dialogue_debug = function(gm) if gm.advance_dialogue_line_ptr then gm:advance_dialogue_line_ptr("ch01.alice.first_meeting", 1) end end,
}

return controller_intents
