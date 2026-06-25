local Shared      = require("HMui.menu.data.pages._3_opt_menu_page.tabs._tab_shared")
local Entries     = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.entries")
local Common      = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.common")
local Widgets     = {
    lang_selector   = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.lang_selector"),
    slider          = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.txt_speed_slider"),
    on_off_switcher = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.auto_save_switcher"),
    widget_with_btn = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.reset_defaults_btn"),
}

local M = {
    --- basic settings
    x = 0.01,                           y = 0,         r = -0.11,

    --- text settings
    key = "opt_system",                 text_i18n_key = "system",
    description_i18n_key = "system",

    child_widgets = {},
}

--- Helper: control_args
local function control_args(gm, entry)
    local widget = Widgets[entry.widget or entry.control]
    if widget and widget.args then return widget.args(gm, entry) end
    return Common.base_args(gm, entry)
end

--- Helper: build_child_widgets
function M.build_child_widgets(gm)
    return Shared.option_widgets(gm, {
        list_id = "system_option_list",             bar_id = "system_option_slide_bar",
        prev_id = "system_option_prev",             next_id = "system_option_next",
        entries = Entries,                          control_args = control_args,
        scrollable_y = 2.8,                         item_gap = 1.4,
    })
end

return M
