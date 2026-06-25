local class          = require("core.class")
local MotionUtils    = require("HMfns.utils.math.motion_utils")

local max, min, abs  = math.max, math.min, math.abs
local smooth_damp    = MotionUtils.smooth_damp

local Y, N = true, false

local Camera = class:extend()

--- Helper: clamp | orig
local function clamp(v, lo, hi) if lo > hi then return 0.5*(lo + hi) end; return max(lo, min(hi, v)) end
local function _orig()          return { x = 0, y = 0 } end

---------------------------------------------------------
--- Init 
---------------------------------------------------------
function Camera:init(args)
    args = args or {}

    self.target_offset,  self.viewport  = _orig(), { x = args.x or 0, y = args.y or 0, w = args.w or 0, h = args.h or 0 }
    self.bounds,         self.target    = nil,     nil
    self.focus_point                 = nil
    self.zoom_velocity,  self.active    = 0,       Y
    self.velocity,   self.x,   self.y   = _orig(), self.viewport.x, self.viewport.y
    self.target_zoom,    self.zoom      = args.zoom, args.zoom
    self.min_zoom,       self.max_zoom  = args.min_zoom or 1.0,  args.max_zoom or 2.5

    self.motion      = { smooth_time = args.smooth_time or 0.14,      max_speed = args.max_speed or 80,      snap = args.snap or 0.001, }
    self.zoom_motion = { smooth_time = args.zoom_smooth_time or 0.12, max_speed = args.zoom_max_speed or 10, snap = args.zoom_snap or 0.001 }
end


----------------------------------------------------
--- set viewport & set target 
----------------------------------------------------
function Camera:set_viewport(x, y, w, h) local vp = self.viewport; vp.x, vp.y, vp.w, vp.h = x or vp.x, y or vp.y, w or vp.w, h or vp.h; return self end
function Camera:set_target(target, offset_x, offset_y) self.target = target; self.target_offset.x, self.target_offset.y = offset_x or 0, offset_y or 0; return self end
function Camera:set_target_offset(offset_x, offset_y) self.target_offset.x, self.target_offset.y = offset_x or 0, offset_y or 0; return self end
function Camera:set_focus_point(x, y) self.focus_point = self.focus_point or _orig(); self.focus_point.x, self.focus_point.y = x or 0, y or 0; return self end
function Camera:clear_focus_point() self.focus_point = nil; return self end

---------------------------------------------
--- zoom controls
---------------------------------------------
function Camera:clamp_zoom(zoom) return clamp(zoom or self.zoom, self.min_zoom, self.max_zoom) end
function Camera:set_zoom(zoom)   self.zoom = self:clamp_zoom(zoom);        self.target_zoom, self.zoom_velocity = self.zoom, 0; return self end
function Camera:zoom_to(zoom)    self.target_zoom = self:clamp_zoom(zoom); return self end
function Camera:zoom_by(delta)   return self:zoom_to((self.target_zoom or self.zoom) + (delta or 0)) end

---------------------------------------------
--- get view size set bounds | set bounds from tiledmap 
---------------------------------------------
function Camera:get_view_size()         local vp, z = self.viewport, max(self.zoom, 1e-6); return vp.w/z, vp.h/z end
function Camera:set_bounds(x, y, w, h)  self.bounds = { x = x or 0, y = y or 0, w = w or 0, h = h or 0 };  return self end
function Camera:set_bounds_from_tiledmap(map)
    local T = map and map.T;            if not T then return self end
    local margin = 1.
    local x, y, w, h = T.x, T.y, T.w, T.h 
    return self:set_bounds(T.x+3*margin, T.y+3*margin, w-15*margin, h-20*margin)
end

---------------------------------------------
--- get target center 
---------------------------------------------
-- Helper: point_in_parent_space, Mirror GameObj:translate_container() for a single point so camera follow uses the same container-space interpretation as rendering.
local function point_in_parent_space(x, y, container)
    local CT = container and container.T
    if not CT then return x, y end

    local cx, cy = 0.5 * CT.w, 0.5 * CT.h
    local dx, dy = x - cx, y - cy
    local c, s   = math.cos(CT.r or 0), math.sin(CT.r or 0)
    return cx + dx*c - dy*s + CT.x, cy + dx*s + dy*c + CT.y
end

--- Helper: resolve world point 
local function resolve_world_point(x, y, obj)
    local container = obj and obj.container
    local guard = 0

    while container and guard < 16 do
        x, y = point_in_parent_space(x, y, container)
        if container == container.container then break end
        container = container.container
        guard = guard + 1
    end
    return x, y
end

function Camera:resolve_object_point(obj, x, y) return resolve_world_point(x or 0, y or 0, obj) end

---__________________________
--- main: get target center
---__________________________
function Camera:get_target_center()
    local _to = self.target_offset
    local fp = self.focus_point;                if fp then return { x = fp.x + _to.x, y = fp.y + _to.y } end
    local target = self.target;                 if not target then return end
    if target.camera_focus_point then local p = target:camera_focus_point(); if p then return { x = p.x + _to.x, y = p.y + _to.y } end end
    local T = target.VT or target.T;            if not T then return end
    local x, y = T.x + 0.5*T.w, T.y + 0.5*T.h
    x, y = resolve_world_point(x, y, target)

    return { x = x + _to.x, y = y + _to.y }
end

-------------------------------------------------
--- get desired position 
-------------------------------------------------
function Camera:get_desired_position()
    local focus   = self:get_target_center();   if not focus then return self.x, self.y end
    local  b      = self.bounds
    local vw, vh  = self:get_view_size()
    local x,   y  = focus.x - 0.5*vw, focus.y - 0.5*vh

    if not b then return x, y end 
    x, y = clamp(x, b.x, b.x + b.w - vw), clamp(y, b.y, b.y + b.h - vh)
    return x, y
end

-----------------------------------------------
--- snap to target 
-----------------------------------------------
function Camera:snap_to_target()
    self.x,          self.y           = self:get_desired_position()
    self.velocity.x, self.velocity.y  = 0, 0
    return self
end

---------------------------------------------------
--- update
---------------------------------------------------
function Camera:update(dt)
    if not self.active then return end

    local zm, zv = self.zoom_motion, self.zoom_velocity
    if abs(self.zoom - self.target_zoom) <= zm.snap and abs(zv) <= zm.snap then self.zoom, self.zoom_velocity = self.target_zoom, 0
    else self.zoom, self.zoom_velocity = smooth_damp(self.zoom, zv, self.target_zoom, zm.smooth_time, zm.max_speed, dt) end

    local target_x, target_y  = self:get_desired_position()
    local m,        vel       = self.motion, self.velocity

    if abs(self.x - target_x) <= m.snap and abs(vel.x) <= m.snap then self.x, vel.x = target_x, 0
    else self.x, vel.x = smooth_damp(self.x, vel.x, target_x, m.smooth_time, m.max_speed, dt) end

    if abs(self.y - target_y) <= m.snap and abs(vel.y) <= m.snap then self.y, vel.y = target_y, 0
    else self.y, vel.y = smooth_damp(self.y, vel.y, target_y, m.smooth_time, m.max_speed, dt) end
end

------------------------------------------
--- get draw offset |  get view center 
------------------------------------------
function Camera:get_draw_offset()  local vp = self.viewport; return vp.x - self.x, vp.y - self.y end
function Camera:get_view_center()  local vp = self.viewport; return vp.x + 0.5*vp.w, vp.y + 0.5*vp.h end

---------------------------------------------
--- screen_to_world_point
---------------------------------------------
function Camera:screen_to_world_point(point, out)
    local vp, z = self.viewport, max(self.zoom, 1e-6)
    out = out or {}
    out.x, out.y = self.x + (point.x - vp.x)/z, self.y + (point.y - vp.y)/z
    return out
end

----------------------------------------------------
--- World to screen point 
----------------------------------------------------
function Camera:world_to_screen_point(point, out)
    local vp, z = self.viewport, self.zoom
    out = out or {}
    out.x, out.y = vp.x + z*(point.x - self.x), vp.y + z*(point.y - self.y)
    return out
end

return Camera
