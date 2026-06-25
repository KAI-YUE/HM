local TabUtils = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy

local Y, N = true, false

local Core     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.core")
local Controls = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.controls")
local Layout   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.layout")
local Page     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.page")

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
--- Init helpers
----------------------------------
local function _init_child(self, gm, item)
    local HMWidget    = require("HMEng.ui_actors.hm_widget")
    local child_args  = copy(item)
    local T           = child_args.T or {}

    child_args.T  = copy(T)
    local child   = HMWidget(gm, child_args)

    child.parent = self
    child.fx_mask, child.fx_mask_dir = child.fx_mask or 0, child.fx_mask_dir or 1
    child.scrollable_page_base = { x = T.x or 0, y = T.y or 0, w = T.w or child.T.w, h = T.h or child.T.h }

    child:set_role({
        role_type   = "Minor",      offset  = { x = T.x or 0, y = T.y or 0 },
        major       = self,         xy_bond = "Strong",
        wh_bond     = "Strong",     r_bond  = "Strong",
        scale_bond  = "Strong",
    })

    self.children[#self.children + 1] = child
    self.scrollable_page_items[#self.scrollable_page_items + 1] = child
end

-----------------------------
--- Module: init
----------------------------------
function M.init(self, gm)
    self.scrollable_page_items = {}

    for _, item in ipairs(Core.items(self.config)) do _init_child(self, gm, item); end
    Layout.layout_visible(self)
end

M.page         = Page.page
M.scroll       = Page.scroll
M.set_progress = Page.set_progress
M.update       = Page.update
M.draw         = Page.draw
M.hit_test     = Page.hit_test

M.lock_slot_controls   = Controls.lock_slot_controls
M.unlock_slot_controls = Controls.unlock_slot_controls

return M
