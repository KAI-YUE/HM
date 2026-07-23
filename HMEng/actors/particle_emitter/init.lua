local Actor = require("HMEng.actors.actor")
local ParticleEmitter = Actor:extend()

local function install(mod) mod(ParticleEmitter) end
local install_list = {"registry", "move_update", "render"}
for _, pkg in ipairs(install_list) do install(require("HMEng.actors.particle_emitter." .. pkg)) end

-------------------------------------------------------
-- ParticleEmitter: init & Methods 
-------------------------------------------------------
--- Initialize a new ParticleEmitter
function ParticleEmitter:init(gm, x, y, w, h, config) self:init_particle_attributes(gm, x, y, w, h, config) end
--- internal methods 
function ParticleEmitter:_paused() return self.SET.pause and not self.created_on_pause  end

return ParticleEmitter
