local Core     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.core")
local Controls = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.controls")

local Y, N = true, false

local M = {}

-----------------------------
--- Visible layout
----------------------------------
local function _layout_visible(self)
    local items, cfg = self.scrollable_items or {}, self.config
    local n = #items
    if n <= 0 then return end

    local sample   = items[1].scrollable_item_base or items[1].T
    local start    = Core.clamp_start(cfg, n)
    cfg.page_start = start
    Core.hide_all(self)

    for slot = 1, Core.slot_count(cfg, n) do
        local idx   = Core.slot_index(cfg, n, start, slot)
        local child = idx and items[idx]
        if not child then goto continue end
        child.fx_mask, child.fx_mask_dir = child.fx_mask or 0, child.fx_mask_dir or 1
        Core.place_child_at_slot(self, child, sample, slot)
        ::continue::
    end
end

-----------------------------
--- Transition layout
----------------------------------
local function _layout_transition(self, tr)
    local items, cfg = self.scrollable_items or {}, self.config
    local n = #items
    if n <= 0 then return end

    local sample = items[1].scrollable_item_base or items[1].T
    local count  = Core.slot_count(cfg, n)
    local p      = Core.clamp01(tr.progress)

    Core.hide_all(self)
    for _, idx in ipairs(Core.transition_indexes(cfg, n, tr.from, tr.to, count)) do
        local child     = items[idx]
        local from_slot = Core.display_slot and Core.display_slot(cfg, n, tr.from, idx, count) or nil
        local to_slot   = Core.display_slot and Core.display_slot(cfg, n, tr.to, idx, count) or nil

        if not from_slot and to_slot then
            from_slot = to_slot + tr.dir * tr.step
        elseif from_slot and not to_slot then
            to_slot = from_slot - tr.dir * tr.step
        end

        local slot = from_slot + (to_slot - from_slot) * p
        if child then Core.place_child_at_slot(self, child, sample, slot) end
    end
end

-----------------------------
--- Transition lifecycle
----------------------------------
local function _finish_transition(self)
    local cfg = self.config
    local tr  = cfg.page_transition
    if not tr then return end

    cfg.page_start, cfg.page_transition = tr.to, nil
    _layout_visible(self)
    Controls.unlock_slot_controls(self)
end

-----------------------------
--- Draw children
----------------------------------
local function _draw_children(self)
    local tr = self.config.page_transition
    if tr and Core.clamp01(tr.progress) >= 1 then
        _finish_transition(self)
        tr = nil
    end

    if tr then _layout_transition(self, tr) else _layout_visible(self) end
    Core.update_slide_bar(self)

    for _, child in ipairs(self.scrollable_items or {}) do
        if child.states.visible then child:draw(); if child.scrollable_overlay_draw then child.scrollable_overlay_draw(child) end end
    end
end

function M.layout_visible(self)        return _layout_visible(self) end
function M.layout_transition(self, tr) return _layout_transition(self, tr) end
function M.finish_transition(self)     return _finish_transition(self) end
function M.draw_children(self)         return _draw_children(self) end

return M
