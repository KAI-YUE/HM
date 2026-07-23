local Shared      = require("HMui.menu.data.pages._3_opt_menu_page.tabs._tab_shared")
local Entries     = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio.entries")
local Common      = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio.widgets.common")
local Widgets     = {
    slider          = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio.widgets.volume_slider"),
    on_off_switcher = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio.widgets.dialogue_voice_switcher"),
}

local M = {
    --- basic settings
    y = 0.09,       r = -0.12,

    --- text settings 
    key = "opt_audio",                  text_i18n_key = "audio",
    description_i18n_key = "audio",
    
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
        list_id = "audio_option_list",               bar_id = "audio_option_slide_bar",
        prev_id = "audio_option_prev",               next_id = "audio_option_next",
        entries = Entries,                           control_args = control_args,
    })
end

return M
