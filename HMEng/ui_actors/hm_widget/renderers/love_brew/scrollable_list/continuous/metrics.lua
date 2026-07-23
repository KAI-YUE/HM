local max, min = math.max, math.min

local M = {}

--- Helpers: axis | item length | viewport length
function M.axis(cfg) return (cfg.axis or "vertical") == "horizontal" and "horizontal" or "vertical" end
function M.item_length(item, axis) local T = item.scrollable_item_base or item.T; return axis == "horizontal" and (T.w or 0) or (T.h or 0) end
function M.viewport_length(self, axis) return axis == "horizontal" and (self.T.w or 0) or (self.T.h or 0) end

-----------------------------
--- content metrics
-----------------------------
function M.measure(self)
    local items, cfg = self.scrollable_items or {}, self.config
    local axis, gap, pos = M.axis(cfg), cfg.item_gap or 0, 0
    for idx, item in ipairs(items) do
        item.scrollable_item_pos = pos
        pos = pos + M.item_length(item, axis) + (idx < #items and gap or 0)
    end

    local viewport = M.viewport_length(self, axis)
    self.scrollable_content_length, self.scrollable_max_offset = pos, max(0, pos - viewport)
    return axis, pos, viewport, self.scrollable_max_offset
end

function M.clamp_offset(self, offset)
    local cap = self.scrollable_max_offset or 0
    return min(max(offset or 0, 0), cap)
end

function M.progress(self)
    local cap = self.scrollable_max_offset or 0
    return cap > 0 and M.clamp_offset(self, self.scroll_offset)/cap or 0
end

return M
