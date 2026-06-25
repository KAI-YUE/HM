local _tab_dir = "HMui.menu.data.pages._3_opt_menu_page.tabs."

local Shared      = require(_tab_dir .. "._tab_shared")
local Entries     = require(_tab_dir .. "._3_2_vision.entries")
local Common      = require(_tab_dir .. "._3_2_vision.widgets.common")
local Widgets     = {
    resolution_selector        = require(_tab_dir .. "._3_2_vision.widgets.resolution_selector"),
    graphics_quality_selector  = require(_tab_dir .. "._3_2_vision.widgets.graphics_quality_selector"),
    screenmode_selector        = require(_tab_dir .. "._3_2_vision.widgets.screenmode_selector"),
    fps_cap_selector           = require(_tab_dir .. "._3_2_vision.widgets.fps_cap_selector"),
    v_sync_switcher            = require(_tab_dir .. "._3_2_vision.widgets.v_sync_switcher"),
}

local M = {
    --- basic settings
    y = 0.045,         r = -0.15,

    --- text settings 
    key = "opt_vision",                 text_i18n_key = "vision",
    description_i18n_key = "vision",
    
    child_widgets = {},
}

--- Helper: control_args
local function control_args(gm, entry)
    local widget = Widgets[entry.widget or entry.control]
    if widget and widget.args then return widget.args(gm, entry) end
    return Common.base_args(gm, entry)
end

------------------------------------
--- build_child_widgets
------------------------------------
function M.build_child_widgets(gm)
    return Shared.option_widgets(gm, {
        list_id = "vision_option_list",              bar_id = "vision_option_slide_bar",
        prev_id = "vision_option_prev",              next_id = "vision_option_next",
        entries = Entries,                           control_args = control_args,
    })
end

return M
