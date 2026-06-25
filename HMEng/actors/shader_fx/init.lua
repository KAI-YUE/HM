local Actor     = require("HMEng.actors.actor")
local ShaderFX  = Actor:extend()

local function install(mod) mod(ShaderFX) end
local install_list = { "registry", "render", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.actors.shader_fx." .. pkg)) end

-------------------------------------------------------
-- ShaderFX: init & methods
-------------------------------------------------------
function ShaderFX:init(gm, x, y, w, h) self:init_shader_fx_attributes(gm, x, y, w, h) end
function ShaderFX:reset() end

return ShaderFX
