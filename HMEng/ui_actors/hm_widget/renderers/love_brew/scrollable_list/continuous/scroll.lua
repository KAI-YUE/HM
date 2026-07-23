local Metrics  = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.continuous.metrics")
local Layout   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.continuous.placement")
local SlideBar = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.common.slide_bar")

local abs, exp, max = math.abs, math.exp, math.max
local Y, N = true, false

local M = {}

--- Helper: default scroll step
local function _step(self)
    local cfg, item = self.config, (self.scrollable_items or {})[1]
    if cfg.scroll_step then return cfg.scroll_step end
    return item and 0.5*(Metrics.item_length(item, Metrics.axis(cfg)) + (cfg.item_gap or 0)) or 1
end

-----------------------------
--- progress
-----------------------------
function M.get_progress(self) Metrics.measure(self); return Metrics.progress(self) end

function M.set_progress(self, progress)
    Metrics.measure(self)
    local offset = Metrics.clamp_offset(self, (progress or 0)*(self.scrollable_max_offset or 0))
    self.scroll_offset, self.scroll_target = offset, offset
    Layout.layout(self); SlideBar.update(self, Metrics.progress(self))
    return Y
end

-----------------------------
--- scroll
-----------------------------
function M.scroll(self, Ctrl, dir, count)
    if self.save_menu_enter_lock then return N end
    Metrics.measure(self)
    local from = Metrics.clamp_offset(self, self.scroll_target or self.scroll_offset)
    local to = Metrics.clamp_offset(self, from + (dir or 1)*_step(self)*max(count or 1, 1)); if to == from then return N end
    self.scroll_target = to
    return Y
end

function M.ensure_visible(self, item)
    Metrics.measure(self);                  if not item or item.parent ~= self then return N end
    
    local axis, viewport = Metrics.axis(self.config), Metrics.viewport_length(self, Metrics.axis(self.config))
    local start, finish  = item.scrollable_item_pos or 0, (item.scrollable_item_pos or 0) + Metrics.item_length(item, axis)
    local target         = self.scroll_target or self.scroll_offset
    
    if start < target then target = start elseif finish > target + viewport then target = finish - viewport end
    target = Metrics.clamp_offset(self, target); if target == self.scroll_target then return N end
    self.scroll_target = target
    return Y
end

-----------------------------
--- update
-----------------------------
function M.update(self, dt)
    Metrics.measure(self)
    local target  = Metrics.clamp_offset(self, self.scroll_target)
    local offset  = Metrics.clamp_offset(self, self.scroll_offset)
    local delta   = target - offset

    if abs(delta) <= (self.config.scroll_epsilon or 0.001) then offset = target
    else offset = offset + delta*(1 - exp(-(self.config.scroll_speed or 18)*max(dt or 0, 0))) end
    
    self.scroll_offset, self.scroll_target = offset, target
    Layout.layout(self); SlideBar.update(self, Metrics.progress(self))
end

return M
