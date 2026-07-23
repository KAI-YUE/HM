local Items   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.common.items")
local Metrics = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.continuous.metrics")

local max = math.max
local Y, N = true, false

local M = {}

--- Helper: place item
local function _place(self, child, axis, pos, visible, drawn)
    local base, cfg = child.scrollable_item_base or child.T, self.config
    local idx = child.scrollable_item_index or 1
    local bx, by = (cfg.x_bias or 0)*max(0, idx - 1), (cfg.y_bias or 0)*max(0, idx - 1)

    if axis == "horizontal" then child.T.x, child.T.y = pos + bx, (base.y or 0) + by
    else                          child.T.x, child.T.y = (base.x or 0) + bx, pos + by end
    child.T.w, child.T.h = base.w, base.h
    child.role.offset.x, child.role.offset.y = child.T.x, child.T.y
    child.states.visible, child.scrollable_item_visible = drawn, visible
    child.disable_button = child.scrollable_item_disabled or self.disable_button or not visible
    if child.move_with_major then child:move_with_major(0) end
end

-----------------------------
--- layout
-----------------------------
function M.layout(self)
    local axis, _, viewport  = Metrics.measure(self)
    local offset             = Metrics.clamp_offset(self, self.scroll_offset)
    local items, cfg         = self.scrollable_items or {}, self.config
    local sample             = items[1] and Metrics.item_length(items[1], axis) or 0
    local overscan           = max(0, cfg.overscan or 0)*(sample + (cfg.item_gap or 0))

    self.scroll_offset = offset
    for idx, child in ipairs(items) do
        child.scrollable_item_index = idx
        local start    = (child.scrollable_item_pos or 0) - offset
        local finish   = start + Metrics.item_length(child, axis)
        local visible  = finish > 0 and start < viewport
        local drawn    = finish > -overscan and start < viewport + overscan
        _place(self, child, axis, start, visible, drawn)
        if drawn then Items.set_clip_parent(child, self) end
    end
end

return M
