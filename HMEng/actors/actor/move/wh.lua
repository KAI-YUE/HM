local MotionUtils = require("HMfns.utils.math.motion_utils")

local smooth_damp = MotionUtils.smooth_damp
local abs         = math.abs

local Y, N = true, false

return function(Actor)
---------------------------------------------
--- Move width_height
---------------------------------------------
--- Helper: _is_small_scale | _lerp | _ease_in_cubic | _ease_out_cubic | _pinch_target | _near
local function _is_small_scale(dw, dh, vel, th) return abs(dw) <= th and abs(dh) <= th and abs(vel.w) <= th and abs(vel.h) <= th end
local function _lerp(a, b, t)                   return a + (b - a)*t end
local function _ease_in_cubic(t)                return t*t*t end
local function _ease_out_cubic(t)               local u = 1 - t; return 1 - u*u*u end
local function _pinch_target(T, p)              return (p.x and (p.min_w or 0.) or T.w), (p.y and (p.min_h or 0.) or T.h) end
local function _near(a, b, eps)                 return abs((a or 0) - (b or 0)) <= eps end

--- Helper: _should_use_pinch_motion
local function _should_use_pinch_motion(self, tw, th, eps)
    local p, ptr, VT = self.pinch, self.pinch_transition, self.VT;          if ptr or p.x or p.y then return Y end
    return (_near(VT.w, p.min_w or 0, eps) and not _near(VT.w, tw, eps)) or (_near(VT.h, p.min_h or 0, eps) and not _near(VT.h, th, eps))
end

--- Helper: _start_pinch_transition
local function _start_pinch_transition(self, tw, th)
    local p, motion  = self.pinch, self.motion.wh
    local VT, ptr    = self.VT, self.pinch_transition or {}
    local closing    = p.x or p.y

    ptr.from_w, ptr.from_h  = VT.w, VT.h
    ptr.to_w,   ptr.to_h    = tw,   th
    ptr.t,      ptr.dur     = 0,    closing and (motion.pinch_in_dur or 0.08) or (motion.pinch_out_dur or 0.12)
    ptr.ease,   ptr.axis    = closing and "in" or "out", ptr.axis or (p.x and "x") or (p.y and "y")
    self.pinch_transition   = ptr
    return ptr
end

--- Helper: _finish_pinch_transition
local function _finish_pinch_transition(self, ptr, p, tw, th)
    local VT, vel = self.VT, self.velocity
    VT.w, VT.h, vel.w, vel.h, self.stay = tw, th, 0, 0, Y

    if ptr.auto_release and ptr.axis and p[ptr.axis] then p[ptr.axis] = N; self.pinch_transition = nil; return end
    self.pinch_transition = nil
end

--- Helper: _move_pinch_wh
local function _move_pinch_wh(self, dt, tw, th, eps)
    local ptr = self.pinch_transition
    if not ptr or ptr.to_w ~= tw or ptr.to_h ~= th then ptr = _start_pinch_transition(self, tw, th) end

    local dur = ptr.dur or 0
    if dur <= 0 then _finish_pinch_transition(self, ptr, self.pinch, tw, th); return Y end

    ptr.t = math.min((ptr.t or 0) + dt, dur)
    local u = ptr.t / dur
    local k = (ptr.ease == "in") and _ease_in_cubic(u) or _ease_out_cubic(u)

    local VT, vel = self.VT, self.velocity
    local old_w, old_h = VT.w, VT.h
    VT.w, VT.h = _lerp(ptr.from_w, ptr.to_w, k), _lerp(ptr.from_h, ptr.to_h, k)
    vel.w, vel.h = VT.w - old_w, VT.h - old_h
    self.stay = N

    if ptr.t >= dur or _is_small_scale(VT.w - tw, VT.h - th, vel, eps) then _finish_pinch_transition(self, ptr, self.pinch, tw, th) end
    return Y
end

---______________________________
--- main: move_wh 
---______________________________
function Actor:move_wh(dt)
    local T, VT, p   = self.T, self.VT, self.pinch
    local motion     = self.motion.wh 
    local tw,  th    = _pinch_target(T, p)
    local vel, eps   = self.velocity, motion.snap

    if _should_use_pinch_motion(self, tw, th, eps) then return _move_pinch_wh(self, dt, tw, th, eps) end

    if _is_small_scale(VT.w - tw, VT.h - th, vel, eps) then
        VT.w, VT.h, vel.w, vel.h, self.stay = tw, th, 0, 0, Y
        local ptr = self.pinch_transition
        if ptr and p[ptr.axis] then p[ptr.axis], self.pinch_transition = N, nil end
        return
    end 

    local smooth_time, max_speed = motion.smooth_time, motion.max_speed

    self.stay = N
    local vw_sec, vh_sec = vel.w/ dt, vel.h/dt
   
    VT.w,  vw_sec  = smooth_damp(VT.w, vw_sec, tw, smooth_time, max_speed, dt)
    VT.h,  vh_sec  = smooth_damp(VT.h, vh_sec, th, smooth_time, max_speed, dt)
    vel.w, vel.h   = vw_sec * dt, vh_sec * dt

    if abs(VT.w - tw) < eps and abs(vel.w) < eps then VT.w, vel.w = tw, 0 end
    if abs(VT.h - th) < eps and abs(vel.h) < eps then VT.h, vel.h = th, 0 end
    
    if VT.w ~= tw or VT.h ~= th or vel.w ~= 0 and vel.h ~= 0 then return end
    
    self.stay = Y
    local ptr = self.pinch_transition
    if ptr and p[ptr.axis] then p[ptr.axis], self.pinch_transition = N, nil end
end

end
