local Slot = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.slot")

local Y, N = true, false

local M = {}

-----------------------------
--- Control helpers
----------------------------------
--- Helper: _clear_ctrl_slot_targets
local function _clear_ctrl_slot_targets(self)
    local Ctrl = self.Ctrl;         if not Ctrl then return end

    for _, key in ipairs({ "clicked", "hovering", "cursor_hover", "cursor_down", "cursor_up" }) do
        local state = Ctrl[key]
        if state and Slot.is_page_slot(self, state.target) then state.target, state.handled = nil, Y end
        if state and Slot.is_page_slot(self, state.prev_target) then state.prev_target = nil end
    end
end

--- Helper: _lock_slot_controls
local function _lock_slot_controls(self)
    local lock = {}
    self.scrollable_page_ctrl_lock = lock

    for _, child in ipairs(self.scrollable_page_items or {}) do
        local st = child.states
        lock[child] = { hover_can = st.hover.can, click_can = st.click.can }
        st.hover.can, st.hover.is, st.click.can = N, N, N
    end

    _clear_ctrl_slot_targets(self)
end

--- Helper: _unlock_slot_controls
local function _unlock_slot_controls(self)
    local lock = self.scrollable_page_ctrl_lock;            if not lock then return end
    for child, saved in pairs(lock) do if not child.REMOVED then local st = child.states; st.hover.can, st.click.can = saved.hover_can, saved.click_can; end; end

    self.scrollable_page_ctrl_lock = nil
end

--- Helper: _set_start
local function _set_start(cfg, start, n)
    local old      = cfg.page_start
    cfg.page_start = start
    local clamped  = Slot.clamp_start(cfg, n)
    cfg.page_start = old
    return clamped
end

function M.clear_ctrl_slot_targets(self) return _clear_ctrl_slot_targets(self) end
function M.lock_slot_controls(self)      return _lock_slot_controls(self) end
function M.unlock_slot_controls(self)    return _unlock_slot_controls(self) end
function M.set_start(cfg, start, n)      return _set_start(cfg, start, n) end

return M
