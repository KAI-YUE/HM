local Actor = require("HMEng.actors.actor")
local TiledMap = Actor:extend()

local function install(mod) mod(TiledMap) end
local install_list = { "registry", "ops", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.bg.tiledmap." .. pkg)) end

local Y = true

--------------------------------
--- init 
--------------------------------
function TiledMap:init(gm, x, y, w, h, config) self:init_map_attributes(gm, x, y, w, h, config) end

----------------------------------
--- set tile shader
----------------------------------
function TiledMap:set_tile_shader(shader, opts)
    self.tile_shader, self.tile_shader_opts = shader, opts or self.tile_shader_opts or {}
    self:mark_all_chunks_dirty()
end

return TiledMap
