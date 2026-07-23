local Y, N = true, false

local Items    = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.common.items")
local Core     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.core")
local Controls = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.controls")
local Layout   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.layout")
local Page     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.page")

local M = {}

M.config_keys = {
    "axis",                  "page_start",     "visible_count", "page_step", "loop",
    "scroll_fast_threshold",
    "item_gap",              "page_duration", "page_ease", "page_fx_stagger",
    "slide_bar_id",          "slide_bar_track",
    "x_bias",                "y_bias",
    "child_widgets",
}

M.draws_children        = Y
M.handles_child_widgets = Y

-----------------------------
--- Module: init
----------------------------------
function M.init(self, gm)
    Items.init(self, gm, { slot_fx = Y })
    Layout.layout_visible(self)
end

M.page         = Page.page
M.scroll       = Page.scroll
M.set_progress = Page.set_progress
M.get_progress = Page.get_progress
M.update       = Page.update
M.draw         = Page.draw
M.hit_test     = Page.hit_test

M.lock_slot_controls   = Controls.lock_slot_controls
M.unlock_slot_controls = Controls.unlock_slot_controls

return M
