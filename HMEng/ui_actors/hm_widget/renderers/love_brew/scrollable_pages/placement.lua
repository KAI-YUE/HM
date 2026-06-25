local Slot = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.slot")

local max = math.max

local Y, N = true, false

local M = {}

-----------------------------
--- Placement helpers
----------------------------------
--- Helper: _item_gap
local function _item_base(self, sample, slot)
    local cfg  = self.config
    local gap  = cfg.item_gap or 0
    if (cfg.axis or "vertical") == "horizontal" then return (slot - 1) * ((sample.w or 0) + gap), 0 end
    return 0, (slot - 1) * ((sample.h or 0) + gap)
end

--- Helper: _slot_disabled | _slot_bias | hide_all
local function _slot_disabled(self, slot, visible) return self.disable_button or (slot > visible) and Y end
local function _slot_bias(cfg, slot)               local i = max(0, (slot or 1) - 1); return (cfg.x_bias or 0) * i, (cfg.y_bias or 0) * i; end
local function _hide_all(self)                     for _, child in ipairs(self.scrollable_page_items or {}) do child.disable_button, child.states.visible = Y, N; end; end

--- Helper: _sync_child_tree_to_slot
local function _sync_child_tree_to_slot(child, slot)
    if child.move_with_major then child:move_with_major(0) end
    child.fx_mask, child.fx_mask_dir = slot.fx_mask, slot.fx_mask_dir
    for _, sub in ipairs(child.children or {}) do _sync_child_tree_to_slot(sub, slot) end
end

--- Helper: _place_child_at_slot
local function _place_child_at_slot(self, child, sample, slot)
    local cfg, base  = self.config, child.scrollable_page_base or child.T
    local x,   y     = _item_base(self, sample, slot)
    local bx,  by    = _slot_bias(cfg, slot)
    local visible    = Slot.visible_count(cfg, #(self.scrollable_page_items or {}))

    child.T.x,            child.T.y              = x + bx, y + by
    child.role.offset.x,  child.role.offset.y    = child.T.x, child.T.y
    child.T.w,            child.T.h              = base.w, base.h
    child.disable_button, child.states.visible   = _slot_disabled(self, slot, visible), Y
    _sync_child_tree_to_slot(child, child)
end

function M.item_base(self, sample, slot)                   return _item_base(self, sample, slot) end
function M.slot_disabled(self, slot, visible)              return _slot_disabled(self, slot, visible) end
function M.slot_bias(cfg, slot)                            return _slot_bias(cfg, slot) end
function M.hide_all(self)                                  return _hide_all(self) end
function M.sync_child_tree_to_slot(child, slot)            return _sync_child_tree_to_slot(child, slot) end
function M.place_child_at_slot(self, child, sample, slot)  return _place_child_at_slot(self, child, sample, slot) end

return M
