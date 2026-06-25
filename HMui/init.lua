local push = table.insert
local M = {}

local _data_pages = "HMui.menu.data.pages."

-- one-shot requires (dot notation)
local mods = {
    -- debug 
    debug_actions    = require("HMui.debug.actions"),                               

    -- decorators                      
    dec_profile      = require("HMui.decorators.profile"),                          dec_shop         = require("HMui.decorators.shop"),
    
    -- menu 
    menu_mgr  = require("HMui.menu.menu_mgr"),                                      menu_switch = require("HMui.menu.menu_switch"),
    menu_save_confirm = require(_data_pages .. "_1_load_2_save_pages._2_save.save_confirm"),
    menu_load_confirm = require(_data_pages .. "_1_load_2_save_pages._1_load.load_confirm"), menu_options_tabs = require(_data_pages .. "_3_opt_menu_page.tabs.tab_ops.tab_switch"), 
    menu_delete_confirm = require(_data_pages .. "_1_load_2_save_pages._shared.delete_confirm"),
    menu_system_settings_confirm = require(_data_pages .. "_3_opt_menu_page.settings_confirm"),

    -- text input/entry 
    text_entry       = require("HMui.text_input.text_entry"),
}

-- Helpers --------------------------------------------------------------------
local function ensure_ns(root, dotted)
	local t = root
	for seg in dotted:gmatch("[^%.]+") do t[seg] = t[seg] or {};  t = t[seg] end
	return t
end

local function set_func(root, dotted, fn, source)
	local parts = {}
	for seg in dotted:gmatch("[^%.]+") do parts[#parts+1] = seg end
	local last = parts[#parts]
	local tbl = (#parts > 1) and ensure_ns(root, table.concat(parts, ".", 1, #parts-1)) or root
	assert(type(tbl[last]) ~= "function", ("Duplicate gm.Fs key: %s (from %s)"):format(dotted, source))
	assert(type(tbl[last]) ~= "table", ("Name conflict (table exists) for %s (from %s)"):format(dotted, source))
	tbl[last] = fn
end

local function wrap_pure(fn)
return function(a, ...)
    if type(a) == "table" and (a.Fs or a.SET or a.Ver) then return fn(...)
    else return fn(a, ...) end  -- If first arg “looks like gm” (a table with Fs/SET/etc), drop it.
end
end

local exports = {
    -- Decorator: Profile & Save 
	{ to="can_continue",             mod="dec_profile",       fn="can_continue",                kind="gm" },
    { to="can_load_profile",         mod="dec_profile",       fn="can_load_profile",            kind="gm" },
	{ to="can_delete_profile",       mod="dec_profile",       fn="can_delete_profile",          kind="gm" },
	{ to="can_unlock_all",           mod="dec_profile",       fn="can_unlock_all",              kind="gm" },
   	-- Decorator: Shop related 
	{ to="can_buy",           	     mod="dec_shop",     	  fn="can_buy",          	 	    kind="gm" },
	{ to="can_buy_and_use",   	     mod="dec_shop",     	  fn="can_buy_and_use",   	        kind="gm" },
	{ to="can_redeem",        	     mod="dec_shop",     	  fn="can_redeem",        	        kind="gm" },
	{ to="can_open",          	     mod="dec_shop",     	  fn="can_open",          	        kind="gm" },

    -- Menu 
    { to="open_pause_menu",          mod="menu_mgr",          fn="open_pause_menu",            kind="gm" },
    { to="open_load_menu",           mod="menu_mgr",          fn="open_load_menu",              kind="gm" },
    { to="pause2load_menu",          mod="menu_switch",       fn="pause2load_menu",             kind="gm" },
    { to="load2pause_menu",          mod="menu_switch",       fn="load2pause_menu",             kind="gm" },
    { to="load_slot",                mod="menu_load_confirm", fn="load_slot",                   kind="gm" },
    { to="confirm_load_slot_no",     mod="menu_load_confirm", fn="confirm_load_slot_no",        kind="gm" },
    { to="confirm_load_slot_yes",    mod="menu_load_confirm", fn="confirm_load_slot_yes",       kind="gm" },
    { to="pause2save_menu",          mod="menu_switch",       fn="pause2save_menu",             kind="gm" },
    { to="save2pause_menu",          mod="menu_switch",       fn="save2pause_menu",             kind="gm" },
    { to="pause2options_menu",       mod="menu_switch",       fn="pause2options_menu",          kind="gm" },
    { to="options2pause_menu",       mod="menu_switch",       fn="options2pause_menu",          kind="gm" },
    { to="opt_tab_switch",           mod="menu_options_tabs", fn="opt_tab_switch",              kind="gm" },
    { to="save_slot",                mod="menu_save_confirm", fn="save_slot",                   kind="gm" },
    { to="confirm_save_slot_no",     mod="menu_save_confirm", fn="confirm_save_slot_no",        kind="gm" },
    { to="confirm_save_slot_yes",    mod="menu_save_confirm", fn="confirm_save_slot_yes",       kind="gm" },
    { to="delete_save_slot",         mod="menu_delete_confirm", fn="delete_save_slot",           kind="gm" },
    { to="confirm_delete_slot_no",   mod="menu_delete_confirm", fn="confirm_delete_slot_no",       kind="gm" },
    { to="confirm_delete_slot_yes",  mod="menu_delete_confirm", fn="confirm_delete_slot_yes",      kind="gm" },
    { to="open_system_settings_confirm", mod="menu_system_settings_confirm", fn="open_system_settings_confirm", kind="gm" },
    { to="confirm_system_settings_no",   mod="menu_system_settings_confirm", fn="confirm_system_settings_no",   kind="gm" },
    { to="confirm_system_settings_yes",  mod="menu_system_settings_confirm", fn="confirm_system_settings_yes",  kind="gm" },
    { to="handle_escape",            mod="menu_mgr",          fn="handle_escape",               kind="gm" },
    { to="close_menu",               mod="menu_mgr",          fn="close_menu",                  kind="gm" },
    { to="quick_resume_menu",        mod="menu_mgr",          fn="quick_resume_menu",           kind="gm" },
    { to="return_title",             mod="menu_mgr",          fn="return_title",                kind="gm" },
    { to="launch_title_page",   mod="menu_mgr",          fn="launch_title_page",      kind="gm" },
    { to="title_page_press_any",    mod="menu_mgr",      fn="title_page_press_any",   kind="gm" },
    { to="title_page_back_to_preparation", mod="menu_mgr", fn="title_page_back_to_preparation", kind="gm" },
    { to="title_page_can_continue", mod="menu_mgr",      fn="title_page_can_continue", kind="gm" },
    { to="title_page_new_game",     mod="menu_mgr",      fn="title_page_new_game",    kind="gm" },
    { to="title_page_continue",     mod="menu_mgr",      fn="title_page_continue",    kind="gm" },
    { to="title_page_options",      mod="menu_mgr",      fn="title_page_options",     kind="gm" },
    { to="title_page_options_back", mod="menu_mgr",      fn="title_page_options_back", kind="gm" },
    { to="title_page_quit",         mod="menu_mgr",      fn="title_page_quit",        kind="gm" },

    -- Text entry
    { to="read_input_text",          mod="text_entry",        fn="read_input_text",             kind="pure" },
    { to="move_txt_cursor",          mod="text_entry",        fn="move_txt_cursor",             kind="pure" },
    { to="on_text_input_keydown",    mod="text_entry",        fn="on_text_input_keydown",       kind="pure" },

    -- Debug 
    { to="DT_add_money",             mod="debug_actions",     fn="DT_add_money",                kind="gm" },
    { to="DT_rich",                  mod="debug_actions",     fn="DT_rich",                     kind="gm" },
    { to="DT_win_game",              mod="debug_actions",     fn="DT_win_game",                 kind="gm" },
    { to="DT_lose_game",             mod="debug_actions",     fn="DT_lose_game",                kind="gm" },
}

function M.register(gm)
	gm.Fs = gm.Fs or {}
	for _, e in ipairs(exports) do
		local source  = ("ui.%s.%s"):format(e.mod, e.fn)
		local modtbl  = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
		local fn      = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
		local out_fn  = (e.kind == "pure") and wrap_pure(fn) or fn
		set_func(gm.Fs, e.to, out_fn, source)
	end
end

return M
