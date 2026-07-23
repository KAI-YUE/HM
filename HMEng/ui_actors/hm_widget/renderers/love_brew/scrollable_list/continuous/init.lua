local Items     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.common.items")
local Layout    = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.continuous.placement")
local Scroll    = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.continuous.scroll")
local Viewport  = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.continuous.viewport")

local Y, N = true, false

local M = {}

M.config_keys = {
    "axis",            "item_gap",       "child_widgets",
    "scroll_offset",   "scroll_step",    "scroll_speed",    "scroll_epsilon",
    "overscan",        "clip_mode",      "slide_bar_id",    "slide_bar_track",
    "x_bias",          "y_bias",
}

M.draws_children        = Y
M.handles_child_widgets = Y

-----------------------------
--- init
-----------------------------
function M.init(self, gm)
    Items.init(self, gm, { clipped = Y })
    self.scroll_offset, self.scroll_target = self.config.scroll_offset or 0, self.config.scroll_offset or 0
    self.scrollable_contains_point = Viewport.contains
    Layout.layout(self)
end

-----------------------------
--- draw
-----------------------------
function M.draw(self)
    Layout.layout(self)
    local clip = Viewport.begin_clip(self)
    for _, child in ipairs(self.scrollable_items or {}) do
        if child.states.visible then child:draw(); if child.scrollable_overlay_draw then child.scrollable_overlay_draw(child) end end
    end
    Viewport.end_clip(clip)
end

M.scroll         = Scroll.scroll
M.set_progress   = Scroll.set_progress
M.get_progress   = Scroll.get_progress
M.ensure_visible = Scroll.ensure_visible
M.update         = Scroll.update
M.hit_test       = function() return N end

return M
