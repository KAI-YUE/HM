local Actor, C = require("HMEng.actors.actor"), require("HMfns.animate.color.color_const")
local TabUtils = require("HMfns.utils.table_utils")
local states   = { "hover", "click", "collide", "drag", "release_on" }

local _destroy = TabUtils.destroy_tree
local push     = table.insert
local Y, N     = true, false

return function (ParticleEmitter)
-------------------------------------------------------------------------
--- Init particle attributes
-------------------------------------------------------------------------
--- Helper: handle attach 
function ParticleEmitter:_handle_attach(config)
    self:set_alignment({ major = config.attach, type = "cm", bond = "Strong" })
    local parent, T = self.role.major, self.T;     
    push(parent.children, self);                self.parent = parent
    local pT, _p = parent.T, self.padding;      T.x, T.y    = pT.x + _p, pT.y + _p
    if self.fill then T.w, T.h = pT.w - _p, pT.h - _p end
end

--- Helper: loop update 
function ParticleEmitter:_loop_update(pt, secs)
    self.last_real_time = self.last_real_time - pt/secs
    self:update(pt/secs);            self:move(pt/secs)
end

--_________________________________________
--- Main: init the attributes
--_________________________________________
function ParticleEmitter:init_particle_attributes(gm, x, y, w, h, config)
    Actor.init(self, gm, x, y, w, h)
    
    local config, secs, pt  = config or {}, 60, 15
    self.fill, self.padding = config.fill, config.padding or 0
    if config.attach then self:_handle_attach(config) end
    
    local st, _T = self.states, self._T
    for _, k in ipairs(states) do st[k].can = N end 

    self.timer, self.last_drawn     = config.timer or 0.5, 0
    self.timer_type, self.lifespan  = "real_s", config.lifespan or 1                                  
    if config.timer_type and not self.created_on_pause then self.timer_type = config.timer_type end
    
    self.draw_alpha, self.speed      = 0, config.speed or 1
    self.max,        self.pulse_max  = config.max or math.huge, math.min(20, config.pulse_max or 0)
    self.particles,  self.scale      = {}, config.scale or 1
    self.pulsed, self.vel_variation  = 0, config.vel_variation or 1
    self.last_real_time, self.colors = _T[self.timer_type] - self.timer, config.colors or { C.BACKGROUND.D }
    
    self.EM = gm.E_MANAGER -- game manager registries 

    if getmetatable(self) == ParticleEmitter then push(self.RACTOR, self) end
    if not config.initialize then return end
    for i = 1, secs do self:_loop_update(pt, secs) end
end

-----------------------------------------------------
--- Remove 
----------------------------------------------------
--- Helper: remove peers 
function ParticleEmitter:_remove_peers()
    local peers = self.role.major.children
    for k, v in pairs(peers) do if v == self and type(k) == "number" then table.remove(peers, k) end end
end

--- Main: remove itself
function ParticleEmitter:remove()
    if self.role.major then self:_remove_peers() end
    _destroy(self.children)
    Actor.remove(self)
end

end