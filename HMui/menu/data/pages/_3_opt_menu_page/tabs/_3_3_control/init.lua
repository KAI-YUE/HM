local Shared      = require("HMui.menu.data.pages._3_opt_menu_page.tabs._tab_shared")
local Entries     = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_3_control.entries")

local M = {
    --- basic settings
    y = -0.015,         r = -0.09,

    --- text settings 
    key = "opt_control",                text_i18n_key = "control",
    description_i18n_key = "control",
    
    child_widgets = {},
}

--- Helper: control_args
local function control_args(_, entry) return entry.args or entry end

--- Helper: build_child_widgets
function M.build_child_widgets(gm)
    return Shared.option_widgets(gm, {
        list_id = "control_option_list",            bar_id = "control_option_slide_bar",
        prev_id = "control_option_prev",            next_id = "control_option_next",
        entries = Entries,                          control_args = control_args,
    })
end

return M
