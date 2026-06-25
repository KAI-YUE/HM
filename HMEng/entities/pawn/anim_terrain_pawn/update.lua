local Pawn                 = require("HMEng.entities.pawn")
local install_gust_update  = require("HMEng.entities.pawn.anim_terrain_pawn.params_update.gust")

return function (AnimTerrainPawn)
install_gust_update(AnimTerrainPawn)

--------------------------------------------------
--- update
--------------------------------------------------
function AnimTerrainPawn:update(dt)
    Pawn.update(self, dt)
    if not self.model then return end
    self.model:update(dt)
    self:update_gust_movement(dt)
end

end
