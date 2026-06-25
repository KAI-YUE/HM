local min, max       = math.min, math.max
local abs, exp, pi, sqrt = math.abs, math.exp, math.pi, math.sqrt

local Y, N = true, false

return function (Pawn)
-------------------------------------------------------
--- update_bounce
-------------------------------------------------------
--- Helper: _bounce_sx & begin settle 
local function _bounce_sx(bn, sy) local stretch = max(0, 1 - sy); return 1 + (bn.width_gain or 0)*stretch end
local function _begin_settle(bn) bn.phase, bn.t, bn.vy = "settle", 0, 0 end

--- Helper: sync draw bounce 
local function _sync_draw_bounce(self, bn)
    self.draw_alpha   = bn.alpha or 1
    self.draw_scale_x,  self.draw_scale_y   = bn.sx or 1, bn.sy or 1
    self.draw_anchor_x, self.draw_anchor_y  = 0.5, 1
end

--- Helper: finish bounce 
local function _finish_bounce(self, bn)
    bn.active, bn.phase, bn.t,  bn.vy       = N, "idle", 0, 0
    bn.alpha,  bn.sx,    bn.sy, bn.amp      = 1, 1, bn.target_sy or 1, 0
    bn.decay_rate, bn.spring_dur, bn.omega, bn.omega_start = 0, 0, 0, 0
    _sync_draw_bounce(self, bn)
end

--- Helper: clear draw bounce 
local function _clear_draw_bounce(self)
    if (self.draw_alpha == nil) and (self.draw_scale_x == nil) and (self.draw_scale_y == nil) then return end
    self.draw_alpha, self.draw_scale_x, self.draw_scale_y = 1, 1, 1
end

--- Helper: update appear bounce
local function _update_appear_bounce(self, bn, dt)
    bn.t = bn.t + dt
    local dur = max(bn.appear_dur or 0, 1e-6)
    local p   = bn.t / dur

    local function _handle_rest()
        bn.alpha = p
        bn.sx = 1 + ((bn.squash_sx or 1) - 1) * p
        bn.sy = 0.02 + ((bn.squash_sy or 0.18) - 0.02) * p
        _sync_draw_bounce(self, bn)
    end

    if p < 1 then return _handle_rest() end

    bn.phase, bn.t, bn.alpha  = "spring", 0, 1
    bn.sy, bn.sx              = bn.squash_sy, bn.squash_sx

    local target, spring_dur  = bn.target_sy or 1, (bn.total_dur or 0) - dur
    local k, x0, peak         = bn.spring_k or 0, (bn.squash_sy or 0.18) - target, max(target, bn.first_peak_sy or target)
    local a      = peak - target; 
    local base_v = sqrt(max(0, k*max(0, a*a - x0*x0)))

    bn.amp,         bn.decay_rate   = a, max(0, bn.spring_damp or 0)
    bn.spring_dur,  bn.omega        = spring_dur, max(sqrt(k), ((bn.min_cycles or 0)*2*pi)/spring_dur)

    local launch_boost = max(1, bn.launch_boost or 1)
    bn.omega_start, bn.vy = bn.omega * 0.32 * launch_boost, max(base_v, bn.pop_velocity or 0)
    _sync_draw_bounce(self, bn)
    return _handle_rest()
end

--- Helper: update settle bounce
local function _update_settle_bounce(self, bn, dt)
    bn.t = bn.t + dt
    local target = bn.target_sy or 1
    local speed  = max(1e-6, bn.settle_speed or 14)
    local blend  = 1 - exp(-speed * dt)

    bn.sy = (bn.sy or target) + (target - (bn.sy or target)) * blend
    bn.sx = (bn.sx or 1) + (1 - (bn.sx or 1)) * blend
    bn.alpha = 1

    if abs((bn.sy or target) - target) <= 0.002 and abs((bn.sx or 1) - 1) <= 0.002 then return _finish_bounce(self, bn)  end
    _sync_draw_bounce(self, bn)
end

---______________________________
--- main: update_bounce
---______________________________
function Pawn:update_bounce(dt)
    local bn = self.bounce
    if not bn        then return end
    if not bn.active then return _clear_draw_bounce(self) end

    if     bn.phase == "appear" then return _update_appear_bounce(self, bn, dt)
    elseif bn.phase == "settle" then return _update_settle_bounce(self, bn, dt) end

    bn.t = bn.t + dt
    local spring_dur, target       = bn.spring_dur, bn.target_sy or 1
    local dy,         u            = (bn.sy or target) - target, min(1, bn.t / spring_dur)
    local ramp,       omega_start  = u*u*(3 - 2*u), max(1e-6, bn.omega_start or bn.omega or 0)
    
    local omega_end  = max(omega_start, bn.omega or omega_start)
    local omega      = omega_start + (omega_end - omega_start)*ramp
    local damping    = max(0, bn.decay_rate or 0)*(1.6 + 0.95 * ramp)
    local accel      = -(omega*omega)*dy

    bn.vy = (bn.vy or 0) + accel*dt;             bn.vy    = bn.vy*exp(-damping*dt)
    bn.sy = (bn.sy or target) + bn.vy * dt;      bn.alpha = 1
    bn.sx = _bounce_sx(bn, bn.sy)

    if bn.t <= spring_dur then return _sync_draw_bounce(self, bn) end
    _begin_settle(bn)
    _sync_draw_bounce(self, bn)
    return _sync_draw_bounce(self, bn)
end

---------------------------------------------
--- update 
---------------------------------------------
function Pawn:update(dt) self:update_bounce(dt) end

end
