local Slot = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry.slot")
local Common = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.common.slide_bar")

local M = {}

-----------------------------
--- Slide bar helpers
----------------------------------
--- Helper: _page_progress_for_bar
local function _page_progress_for_bar(self)
    local cfg, n  = self.config, #(self.scrollable_items or {});       if n <= 0 then return 0 end
    local tr      = cfg.page_transition;                               if tr then return Slot.transition_progress(cfg, n, tr) end
    local p       = Slot.page_progress(cfg, n, Slot.clamp_start(cfg, n))
    return Slot.clamp01(p)
end

--- Helper: _update_slide_bar
local function _update_slide_bar(self)
    Common.update(self, _page_progress_for_bar(self))
end

function M.page_progress_for_bar(self) return _page_progress_for_bar(self) end
function M.update_slide_bar(self) return _update_slide_bar(self) end

return M
