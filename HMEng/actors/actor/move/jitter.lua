local TabUtils = require("HMfns.utils.table_utils")

local random_pick = TabUtils.random_pick
local sin         = math.sin

local Y = true

return function(Actor)
-------------------------------------------------------
-- Move with jitter
-------------------------------------------------------
function Actor:move_with_jitter(dt)
    local j = self.jitter;                  if not j or j.handled_elsewhere then return end 

    local now    = self._T.real_s
    local t0, t1 = j.start_time or now, j.end_time or now
    local dur    = t1 - t0

    if dur <= 0 or now >= t1 then self.jitter = nil; return end
    local t, remain = now - t0, (t1 - now)/dur
    if remain > 1 then remain = 1 end

    local w_scale,   w_rot    = 50, 40
    local osc_scale, osc_rot  = sin(w_scale * t), sin(w_rot * t)
    j.scale = (j.scale_amt or 0) * osc_scale * (remain ^ 3)
    j.r     = (j.r_amt or 0) * osc_rot * (remain ^ 2)
end

-------------------------------------------------------
-- jitter me
-------------------------------------------------------
function Actor:jitter_me(amount, rot_amt)
    if self.SET.C_static then return end

    local _T, amount   = self._T, amount or 0.4
    local r_amt,  real     = rot_amt or random_pick({ 0.6*amount, -0.6*amount }), _T.real_s
    local end_t,  start_t  = real + 0.4, real
    
    self.jitter   = { scale = 0, scale_amt = amount, r = 0, r_amt = r_amt, start_time = start_t, end_time = end_t }
    self.VT.scale = 1 - 0.6*amount
    return Y
end

-------------------------------------------------------
-- jitter rotation only
-------------------------------------------------------
function Actor:jitter_rot(rot_amt, dur)
    if self.SET.C_static then return end

    local _T  = self._T
    local real    = _T.real_s
    local r_amt   = rot_amt or random_pick({ 0.08, -0.08 })
    self.jitter   = {   scale = 0,     scale_amt = 0, r = 0,
        r_amt = r_amt,  start_time = real,  end_time  = real + (dur or 0.25),
    }
    return Y
end

end
