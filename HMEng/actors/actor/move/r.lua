local MotionUtils = require("HMfns.utils.math.motion_utils")

local smooth_damp = MotionUtils.smooth_damp
local abs         = math.abs

local Y, N = true, false

return function(Actor)
---------------------------------------------
--- Move r: desired rotation: base + velocity-derived tilt + jitter wobble
---------------------------------------------
function Actor:move_r(dt) 
    local T, VT, j, vel = self.T, self.VT, self.jitter, self.velocity
    local motion        = self.motion.r
	local des_r, th     = T.r + 0.015*vel.x/dt + (j and j.r*2 or 0), motion.snap

    if abs(des_r - VT.r) <= th and abs(vel.r) <= th then VT.r, vel.r, self.stay = des_r, 0, Y; return end

    local smooth_time, max_speed = motion.smooth_time, motion.max_speed
    self.stay = N

    local vr_sec = vel.r / dt
    VT.r, vr_sec = smooth_damp(VT.r, vr_sec, des_r, smooth_time, max_speed, dt)
    vel.r = vr_sec*dt

	if abs(VT.r - des_r) < th and abs(vel.r) < th then VT.r, vel.r = des_r, 0 end
    if VT.r == des_r and vel.r == 0 then self.stay = Y end
end

end
