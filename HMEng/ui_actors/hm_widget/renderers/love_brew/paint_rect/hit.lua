local max = math.max
local abs, cos, sin = math.abs, math.cos, math.sin

local Y = true

local M = {}

-----------------------------
--- hit helpers
-----------------------------
--- Helper: rect hit | scale pair
local function _rect_hit(point, T) return point.x >= T.x and point.y >= T.y and point.x <= T.x + T.w and point.y <= T.y + T.h end
local function _scale_pair(v, dx, dy) if type(v) == "number" then return v, v end; v = v or {}; return v.x or v.w or dx, v.y or v.h or dy end

--- Helper: scaled hit rect
local function _scaled_hit_rect(self)
    local cfg, T    = self.config, self.T
    local hsx, hsy  = _scale_pair(cfg.hit_scale, 1, 1)
    local pad, ofs  = cfg.hit_padding or { x = 0, y = 0 }, cfg.hit_offset or { x = 0, y = 0 }
    local sx,  sy   = max(0, hsx + 2*(pad.x or 0)), max(0, hsy + 2*(pad.y or 0))
    local w,   h    = T.w * sx, T.h * sy
    local _x,  _y   = T.x + 0.5*(T.w - w) + (ofs.x or 0), T.y + 0.5*(T.h - h) + (ofs.y or 0)

    return { x = _x, y = _y, w = w, h = h, r = T.r or 0 }
end

---____________________________
--- main: hit_test
---____________________________
function M.hit_test(self, cursor_trans) return Y end

---____________________________
--- main: hit_test_outer
---____________________________
function M.hit_test_outer(self, cursor_trans)
    local cfg = self.config
    if cfg.hit_shape ~= nil and cfg.hit_shape ~= "rect" then return Y end

    local args = self.args
    args.collides_with_point_point         = args.collides_with_point_point or {}
    args.collides_with_point_translation   = args.collides_with_point_translation or {}
    args.collides_with_point_rotation      = args.collides_with_point_rotation or {}

    local p   = args.collides_with_point_point
    p.x, p.y  = cursor_trans.x, cursor_trans.y
    if self.container and self.container ~= self then self:_to_container(p) end

    local T  = _scaled_hit_rect(self)
    local r  = T.r or 0
    if abs(r) < 0.1 then return _rect_hit(p, T) end

    local cx, cy   = T.x + 0.5*T.w, T.y + 0.5*T.h
    local dx, dy   = p.x - cx, p.y - cy
    local cr, sr   = cos(-r), sin(-r)
    local rp       = args.collides_with_point_rotation
    rp.x,    rp.y  = cx + dx*cr - dy*sr, cy + dx*sr + dy*cr
    return _rect_hit(rp, T)
end

---____________________________
--- main: text_layout_box
---____________________________
function M.text_layout_box(self)
    local cfg, VT  = self.config, self.VT
    local sx,  sy  = _scale_pair(cfg.text_box_scale, 1, 1)
    local ofs      = cfg.text_offset or { x = 0, y = 0 }
    local w,   h   = VT.w * max(0, sx), VT.h * max(0, sy)
    local box      = self._paint_rect_text_layout_box or {}
    box.x, box.y, box.w, box.h = 0.5*(VT.w - w) + (ofs.x or 0), 0.5*(VT.h - h) + (ofs.y or 0), w, h
    self._paint_rect_text_layout_box = box
    return box
end

return M
