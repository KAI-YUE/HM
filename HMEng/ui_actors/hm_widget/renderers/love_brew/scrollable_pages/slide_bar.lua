local Slot = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages.slot")
local Tree = require("HMEng.ui_actors.common.tree")

local Y = true

local M = {}

-----------------------------
--- Slide bar helpers
----------------------------------
--- Helper: _page_progress_for_bar
local function _page_progress_for_bar(self)
    local cfg, n  = self.config, #(self.scrollable_page_items or {});  if n <= 0 then return 0 end
    local tr      = cfg.page_transition;                               if tr then return Slot.transition_progress(cfg, n, tr) end
    local p       = Slot.page_progress(cfg, n, Slot.clamp_start(cfg, n))
    return Slot.clamp01(p)
end

--- Helper: _update_slide_bar
local function _update_slide_bar(self)
    local cfg, track = self.config, self.config.slide_bar_track;        if not (cfg.slide_bar_id and track) then return end
    local bar = Tree.find_child_by_id(self.parent, cfg.slide_bar_id);   if not bar then return end
    if bar.states and bar.states.drag and bar.states.drag.is then return end

    local p    = _page_progress_for_bar(self)
    local x1   = track.x1 or track.x or bar.T.x
    local y1   = track.y1 or track.y or bar.T.y
    local x2   = track.x2 or track.x or x1
    local y2   = track.y2 or y1
    local x, y = x1 + (x2 - x1) * p, y1 + (y2 - y1) * p

    if bar.role and bar.role.offset then bar.role.offset.x, bar.role.offset.y = x, y; if bar.move_with_major then bar:move_with_major(0) end
    else                                 bar.T.x, bar.T.y = x, y; end
end

function M.page_progress_for_bar(self) return _page_progress_for_bar(self) end
function M.update_slide_bar(self) return _update_slide_bar(self) end

return M
