local Render = require("HMfns.systems.render")
local LG     = love.graphics

local min, max, floor, ceil = math.min, math.max, math.floor, math.ceil

local M = {}

--- Helper: screen bounds
local function _screen_bounds(self)
    Render.push_actor_draw_transform(self)

    local VT = self.VT
    local x1, y1 = LG.transformPoint(0, 0)
    local x2, y2 = LG.transformPoint(VT.w, 0)
    local x3, y3 = LG.transformPoint(0, VT.h)
    local x4, y4 = LG.transformPoint(VT.w, VT.h)
    LG.pop()
    
    local l, t = floor(min(x1, x2, x3, x4)), floor(min(y1, y2, y3, y4))
    local r, b = ceil(max(x1, x2, x3, x4)), ceil(max(y1, y2, y3, y4))
    return l, t, max(0, r - l), max(0, b - t)
end

-----------------------------
--- clip
-----------------------------
function M.begin_clip(self)
    if self.config.clip_mode == "none" then return end
    local old = { LG.getScissor() }
    local x, y, w, h = _screen_bounds(self)
    LG.intersectScissor(x, y, w, h)
    return old
end

function M.end_clip(old)
    if not old then return end
    if old[1] then LG.setScissor(old[1], old[2], old[3], old[4]) else LG.setScissor() end
end

-----------------------------
--- hit boundary
-----------------------------
function M.contains(self, point)
    local T = self.VT or self.T
    return point.x >= T.x and point.y >= T.y and point.x <= T.x + T.w and point.y <= T.y + T.h
end

return M
