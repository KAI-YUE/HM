local Actor = require("HMEng.actors.actor")
local MeshCard = Actor:extend()

local function install(mod) mod(MeshCard) end
local install_list = { "registry", "build_mesh", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.card.field_card.mesh_card." .. pkg)) end

local Y, N = true, false

-------------------------------------------------------
--- init 
-------------------------------------------------------
function MeshCard:init(card) self:init_mesh_card_attributes(card) end
function MeshCard:is_ready() return self.projected_quad ~= nil end
function MeshCard:set_projected_quad(quad) self.projected_quad, self.needs_mesh_sync = quad, Y end

return MeshCard
