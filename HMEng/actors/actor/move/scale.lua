local MotionUtils = require("HMfns.utils.math.motion_utils")

local smooth_damp = MotionUtils.smooth_damp
local abs         = math.abs

local Y, N = true, false

return function(Actor)
---------------------------------------------
--- Move scale
---------------------------------------------
function Actor:move_scale(dt)
	local T, VT, vel, j, z  = self.T, self.VT, self.velocity, self.jitter, self.zoom
    local motion, sts       = self.motion.scale, self.states
    local drag, hover, th   = sts.drag.is and 0.04 or 0, sts.hover.is and 0.02 or 0, motion.snap
	local des_scale         = T.scale + (z and (drag + hover) or 0) + (j and j.scale or 0) -- desired scale: base + zoom (drag/hover) + jitter effect
	
	if abs(des_scale - VT.scale) <= th and abs(vel.scale) <= th then VT.scale, vel.scale, self.stay = des_scale, 0, Y; return end

    local smooth_time, max_speed = motion.smooth_time, motion.max_speed
    self.stay = N

    local scale_sec
    VT.scale, scale_sec = smooth_damp(VT.scale, vel.scale, des_scale, smooth_time, max_speed, dt)
    vel.scale = scale_sec * dt
    if abs(VT.scale - des_scale) < th and abs(vel.scale) < th then VT.scale, vel.scale = des_scale, 0 end
    if VT.scale == des_scale and vel.scale == 0 then self.stay = Y end
end

end
