local Metrics = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.metrics")

local max, abs = math.max, math.abs
local cos, sin = math.cos, math.sin
local Y, N = true, false

local M = {}

--- Helper: _rect_hit
local function _rect_hit(point, T) return point.x >= T.x and point.y >= T.y and point.x <= T.x + T.w and point.y <= T.y + T.h end

--- Helper: _scaled_hit_rect
local function _scaled_hit_rect(self)
    local cfg, T  = self.config, self.VT or self.T
    local pad     = cfg.hit_padding or { x = 0, y = 0 }
    local w,   h  = T.w*max(0, 1 + 2*(pad.x or 0)), T.h*max(0, 1 + 2*(pad.y or 0))
    return { x = T.x + 0.5*(T.w - w), y = T.y + 0.5*(T.h - h), w = w, h = h, r = T.r or 0 }
end

-----------------------------
-- hit_test_outer
-----------------------------
function M.hit_test_outer(self, cursor_trans)
    local cfg = self.config;        if cfg.hit_shape ~= nil and cfg.hit_shape ~= "rect" then return Y end

    local args = self.args
    args.collides_with_point_translation = args.collides_with_point_translation or {}

    local p   = args.single_sprite_hit_point or {}
    p.x, p.y  = cursor_trans.x, cursor_trans.y
    args.single_sprite_hit_point = p
    if self.container and self.container ~= self then self:_to_container(p) end

    local T, r = _scaled_hit_rect(self), 0
    r = T.r or 0
    if abs(r) < 0.1 then return _rect_hit(p, T) end

    local rp      = args.single_sprite_hit_rotation or {}
    local cx, cy  = T.x + 0.5*T.w,     T.y + 0.5*T.h
    local dx, dy  = p.x - cx,          p.y - cy
    local cr, sr  = cos(-r),           sin(-r)
    rp.x,   rp.y  = cx + dx*cr - dy*sr, cy + dx*sr + dy*cr
    args.single_sprite_hit_rotation = rp
    return _rect_hit(rp, T)
end

--- Helper: _ellipse_hit
local function _ellipse_hit(self, point)
    local SM = self.sprite_metrics;        if not SM then return Y end

    local rcfg, cfg      = self.rcfg, self.config
    local x, y, sx, sy   = Metrics.layout_sprite(self, SM)
    local T, p, tz, pad  = self.T, point, rcfg.tile_size, cfg.hit_padding or { x = 0, y = 0 }

    local dw, dh         = SM.w * sx, SM.h * sy
    local rx, ry         = 0.5*dw*max(0, 1 + (pad.x or 0)), 0.5*dh*max(0, 1 + (pad.y or 0))
    if rx <= 0 or ry <= 0 then return N end

    local px, py = (p.x - T.x)*tz, (p.y - T.y)*tz
    local dx, dy = px - (x + 0.5*dw), py - (y + 0.5*dh)
    return (dx*dx)/(rx*rx) + (dy*dy)/(ry*ry) <= 1
end

---____________________________
--- main: hit_test
---______________________________________
function M.hit_test(self, point)
    local shape = self.config.hit_shape
    if shape == nil or shape == "rect" then return Y end
    if shape == "ellipse" then return _ellipse_hit(self, point) end
    return Y
end

return M
