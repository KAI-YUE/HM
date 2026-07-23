local MotionUtils = require("HMfns.utils.math.motion_utils")

local smooth_damp = MotionUtils.smooth_damp
local abs, sqrt   = math.abs, math.sqrt

local Y, N = true, false

return function(Actor)
---------------------------------------------
--- Move xy 
---------------------------------------------
--- Helper: _is_small_move
local function _is_small_move(dx, dy, vel, th) return abs(dx) <= th and abs(dy) <= th and abs(vel.x) <= th and abs(vel.y) <= th end

--- Helper: _finish_waypoint
local function _finish_waypoint(self, waypoint_T)
    if waypoint_T.landing_smooth_time or waypoint_T.landing_max_speed then self.waypoint_landing = { smooth_time = waypoint_T.landing_smooth_time, max_speed = waypoint_T.landing_max_speed } end
    if waypoint_T.pinch_on_arrive and self.pinch and not self.flipping then
        local axis = waypoint_T.pinch_on_arrive
        self.pinch[axis] = Y
        self.pinch_transition = { axis = axis, auto_release = Y }
    end
    self.waypoint_T = nil
end

--- Helper: _resolve_waypoint_arrival
local function _resolve_waypoint_arrival(self, waypoint_T, T, target_T, x, y, Vx, Vy, dx, dy)
    if not waypoint_T then return waypoint_T, target_T, x, y, dx, dy end

    local arrive_dist = waypoint_T.arrive_dist or 0
    if arrive_dist <= 0 or sqrt(dx*dx + dy*dy) > arrive_dist then return waypoint_T, target_T, x, y, dx, dy end

    _finish_waypoint(self, waypoint_T)
    return nil, T, T.x, T.y, T.x - Vx, T.y - Vy
end

--- Helper: _parse_xy_motion_params
local function _parse_xy_motion_params(self, waypoint_T, motion, dt)
    local smooth_time, max_speed = motion.smooth_time, motion.max_speed

    if     waypoint_T            then smooth_time, max_speed = waypoint_T.smooth_time or smooth_time, waypoint_T.max_speed or max_speed
    elseif self.waypoint_landing then local landing = self.waypoint_landing; smooth_time, max_speed  = landing.smooth_time or smooth_time, landing.max_speed or max_speed end

    return smooth_time, max_speed/dt
end

--_______________________________
-- Main: move_xy 
--_______________________________
function Actor:move_xy(dt)
    local motion, T, VT  = self.motion.xy,  self.T, self.VT
    local th,     vel    = motion.snap,     self.velocity
    local waypoint_T     = self.waypoint_T
    local target_T       = waypoint_T or T
    
    local x, y, Vx, Vy   = target_T.x, target_T.y, VT.x, VT.y
    local dx,   dy       = x - Vx, y - Vy

    waypoint_T, target_T, x, y, dx, dy = _resolve_waypoint_arrival(self, waypoint_T, T, target_T, x, y, Vx, Vy, dx, dy)

    if _is_small_move(dx, dy, vel, th) then
        VT.x, VT.y, vel.x, vel.y, self.stay = x, y, 0, 0, Y
        if waypoint_T     then _finish_waypoint(self, waypoint_T) end
        if not waypoint_T then self.waypoint_landing = nil end
        return
    end

    local smooth_time, max_speed = _parse_xy_motion_params(self, waypoint_T, motion, dt)
    self.stay = N
    
    -- smooth_damp velocity is units/sec; keep vel.{x,y} in per-frame units for legacy callers (e.g. move_r tilt).
    local vx_sec, vy_sec = vel.x/dt, vel.y/dt
    
    VT.x,  vx_sec  = smooth_damp(Vx, vx_sec, x, smooth_time, max_speed, dt)
    VT.y,  vy_sec  = smooth_damp(Vy, vy_sec, y, smooth_time, max_speed, dt)
    vel.x, vel.y   = vx_sec * dt, vy_sec * dt

    if abs(VT.x - target_T.x) < th and abs(vel.x) < th then VT.x, vel.x = target_T.x, 0 end -- snap if close enough
    if abs(VT.y - target_T.y) < th and abs(vel.y) < th then VT.y, vel.y = target_T.y, 0 end
    if VT.x ~= target_T.x or VT.y ~= target_T.y or vel.x ~= 0 or vel.y ~= 0 then return end 
    
    self.stay = Y
    if waypoint_T      then _finish_waypoint(self, waypoint_T) end
    if not waypoint_T  then self.waypoint_landing = nil end
end

end
