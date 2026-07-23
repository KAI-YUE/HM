local Tree = require("HMEng.ui_actors.common.tree")

local M = {}

-----------------------------
--- slide bar
-----------------------------
function M.update(self, progress)
    local cfg, track = self.config, self.config.slide_bar_track;        if not (cfg.slide_bar_id and track) then return end
    local bar = Tree.find_child_by_id(self.parent, cfg.slide_bar_id);   if not bar then return end
    if bar.states and bar.states.drag and bar.states.drag.is then return end

    local p    = math.max(0, math.min(progress or 0, 1))
    local x1   = track.x1 or track.x or bar.T.x
    local y1   = track.y1 or track.y or bar.T.y
    local x2   = track.x2 or track.x or x1
    local y2   = track.y2 or y1
    local x, y = x1 + (x2 - x1)*p, y1 + (y2 - y1)*p

    if bar.role and bar.role.offset then bar.role.offset.x, bar.role.offset.y = x, y; if bar.move_with_major then bar:move_with_major(0) end
    else                                 bar.T.x, bar.T.y = x, y end
end

return M
