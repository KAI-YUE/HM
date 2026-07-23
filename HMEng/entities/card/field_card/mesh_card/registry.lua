local Actor     = require("HMEng.actors.actor")
local TabUtils  = require("HMfns.utils.table_utils")
local LG        = love.graphics

local rand      = math.random
local deep_copy = TabUtils.deep_copy

local Tst  = { "collide", "hover", "click", "drag" }
local Y, N = true, false

return function (MeshCard)
--------------------------------------------
--- Init mesh card attributes
--------------------------------------------
function MeshCard:init_mesh_card_attributes(card)
    local gm, T = card.gm, card.T
    Actor.init(self, gm, T.x, T.y, T.w, T.h)

    self.card,             self.parent             = card, card
    self.projector,        self.meshes             = nil, {}
    self.layered_parallax, self.projected_quad     = nil, nil
    self.needs_mesh_sync,  self.debug_passthrough  = Y, Y

    local st = self.states
    for _, k in ipairs(Tst) do st[k].can = N end; st.visible = Y

    self.t_shaders = gm.t_shaders
end

end
