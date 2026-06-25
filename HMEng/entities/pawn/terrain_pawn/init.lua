local Pawn         = require("HMEng.entities.pawn")
local TerrainPawn  = Pawn:extend()

local function install(mod) mod(TerrainPawn) end
local install_list = { "registry" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.pawn.terrain_pawn." .. pkg)) end

---------------------------------
--- init
---------------------------------
function TerrainPawn:init(gm, x, y, w, h, params) self:init_terrain_pawn_attributes(gm, x, y, w, h, params) end

return TerrainPawn
