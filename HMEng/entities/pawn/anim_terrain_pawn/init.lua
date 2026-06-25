local Pawn            = require("HMEng.entities.pawn")
local AnimTerrainPawn = Pawn:extend()

local function install(mod) mod(AnimTerrainPawn) end
local install_list = { "registry", "update", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.pawn.anim_terrain_pawn." .. pkg)) end

local install_utils = { "misc" }
for _, pkg in ipairs(install_utils) do install(require("HMEng.entities.pawn.anim_terrain_pawn.utils." .. pkg)) end

---------------------------------
--- init
---------------------------------
function AnimTerrainPawn:init(gm, x, y, w, h, params) self:init_anim_terrain_pawn_attributes(gm, x, y, w, h, params) end

return AnimTerrainPawn
