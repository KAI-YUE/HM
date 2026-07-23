local Actor = require("HMEng.actors.actor")
local TabUtils = require("HMfns.utils.table_utils")

local push, cos  = table.insert, math.cos
local abs,  sin  = math.abs, math.sin
local rand, pi   = math.random, math.pi
local _pick, min = TabUtils.random_pick, math.min
local Y, N      = true, false

return function (ParticleEmitter)
----------------------------------------------------
-- Update 
----------------------------------------------------
--- Helper: keep updating 
function ParticleEmitter:_keep_updating() 
    if self._T[self.timer_type] <= self.last_real_time + self.timer then return false end
    if #self.particles >= self.max and self.pulsed >= self.pulse_max then return false end
    return true
end

--- Helper: update_self
function ParticleEmitter:_update_self()
    local T, _r1, _r2   = self.T, 0.5 - rand(), 0.5 - rand()  
    local x, y, w, h, r = 0, 0, T.w, T.h, T.r                 
    
    if self.fill then x, y = _r1*w, _r2*h end  
    self.last_real_time = self.last_real_time + self.timer
    
    local new_offset = { x = x, y = y }
    if self.fill and abs(r) < 0.1 then new_offset = { x = sin(r)*y + cos(r)*x, y = sin(r)*x + cos(r)*y } end
    
    local _d, _f, _s = 2*rand()*pi, 2*rand()*pi, 0.5*rand() + 0.1
    local _v, _r, pe = 0.7*self.speed*(self.vel_variation*rand() + (1-self.vel_variation)), 0.2*(0.5 - rand()), 0
    local _t, _c, _o = self._T[self.timer_type], _pick(self.colors), new_offset
    local _particle  = { draw = N, dir = _d, facing = _d, size = _s, age = 0, velocity = _v, r_vel = _r, 
        e_prev = pe, e_curr = 0, scale = 0, visible_scale = 0, time = _t, color = _c, offset = new_offset }

    push(self.particles, _particle)
    if self.pulsed <= self.pulse_max then self.pulsed = self.pulsed + 1 end
end

--__________________________________
--- Main 
--__________________________________
function ParticleEmitter:update(dt)
    if self:_paused() then self.last_real_time = self._T[self.timer_type] ; return end
    local added_this_frame = 0
    while self:_keep_updating() and added_this_frame < 20 do self:_update_self(); added_this_frame = added_this_frame + 1 end
end

---------------------------------------------------------------
--- Move 
---------------------------------------------------------------
function ParticleEmitter:move(dt)
    if self:_paused() then return end
    Actor.move(self, dt);             local SET, _p = self.SET, self.particles
    if self.timer_type ~= "real_s" then dt = dt*SET.sf end
    local lifespan, _s = self.lifespan, self.scale

    for i = #_p, 1, -1 do
        local p = _p[i]
        p.draw, p.e_vel    = Y, p.e_vel or dt*self.scale
        p.e_prev, p.age    = p.e_curr, p.age + dt
        local age, _o, _v  = p.age, p.offset, p.velocity
        local f_elapse, _d = age/lifespan,    p.dir
        
        p.e_curr = min(2*min(_s*f_elapse, _s*(1 - f_elapse)), _s)
        p.e_vel  = (p.e_curr - p.e_prev)*_s*dt + (1 - _s*dt)*p.e_vel
        p.scale  = p.scale + p.e_vel
        p.scale  = min(2*min(_s*f_elapse, _s*(1 - f_elapse)), _s)

        if p.scale < 0 then table.remove(_p, i); goto continue end
        _o.x, _o.y = _o.x + _v*sin(_d)*dt, _o.y + _v*cos(_d)*dt
        p.facing   = p.facing + p.r_vel*dt
        p.velocity = math.max(0, _v - _v*0.07*dt)
        ::continue::
    end
end

end