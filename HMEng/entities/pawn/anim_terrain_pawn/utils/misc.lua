local Pawn     = require("HMEng.entities.pawn")
local Parallax = require("HMEng.actors.actor.parallax")

return function (AnimTerrainPawn)
-------------------------------------------------------
--- calculate parallax from the model ground contact
-------------------------------------------------------
function AnimTerrainPawn:calculate_parallax()
    Pawn.calculate_parallax(self)

    local room, T, sp = self._room, self.T, self.shadow_parallax;   if not (room and T and sp) then return end
    local contact_x   = self.ground_contact_x or self.draw_anchor_x or 0.5
    
    if (self.draw_scale_x or 1) < 0 then contact_x = 1 - contact_x end

    local contact_T = { x = (T.x or 0) + (T.w or 0)*(contact_x - 0.5), w = T.w }
    sp.x = Parallax.shadow_x(self.gm, room.T, contact_T)
    sp.y = -0.5
end

end
