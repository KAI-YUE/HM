local Pawn = require("HMEng.entities.pawn")

local push = table.insert

local Y, N = true, false

return function (TerrainPawn)
--------------------------------------------------
--- init terrain pawn attributes
--------------------------------------------------
function TerrainPawn:init_terrain_pawn_attributes(gm, x, y, w, h, params)
    params = params or {}
    Pawn.init_pawn_attributes(self, gm, x, y, w, h, params)

    self.parent      = params.parent or params.zone or gm.field or self.parent
    self.kind        = "terrain_pawn"
    self.scale_mode  = params.scale_mode or "fixed"
    self.fixed_scale = params.fixed_scale or params.scale or self.fixed_scale or self.T.scale or 1

    local st = self.states
    st.visible,   st.drag.can   = params.visible,   params.can_drag
    st.hover.can, st.click.can  = params.can_hover, params.can_click

    st.hide_cast.is = N

    self.draw_scale_x, self.draw_scale_y = params.flip_x or self.draw_scale_x or 1, params.flip_y or self.draw_scale_y or 1

    if params.sprite_name then self:assign_visual(params.sprite_name, params.atlas_key) end

    local gR = gm.R
    self.RTPAWN = gR.TERRAINPAWN
    if getmetatable(self) == TerrainPawn then push(self.RTPAWN, self) end
end

--------------------------------------------------
--- remove
--------------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab or {}) do if v == obj then table.remove(tab, i); break end end end
function TerrainPawn:remove() cleanup(self.RTPAWN, self); Pawn.remove(self) end

end
