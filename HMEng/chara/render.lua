local Render = require("HMfns.systems.render")
local LG = love.graphics

local max = math.max
local push_draw_trans  = Render.push_actor_draw_transform
local enqueue_drawable = Render.enqueue_drawable

return function (Chara)
-------------------------------------------------------
--- draw_model
-------------------------------------------------------
function Chara:draw_model()
    if not self.model then return end

    local VT,  dims    = self.VT,           self.model_dims
    local off, mscale  = self.model_offset, self.model_scale
    local sx,  sy      = (VT.w / max(dims.w, 1))*mscale.x, (VT.h / max(dims.h, 1))*mscale.y

    LG.setShader()
    LG.setColor(1, 1, 1, 1)
    self.model:draw(off.x, off.y, 0, sx, sy)
end

-------------------------------------------------------
--- Helper: draw_mesh_model
-------------------------------------------------------
function Chara:draw_mesh_model()
    local mesh = self.model_mesh and self.model_mesh[self.mesh_draw_idx];   if not mesh then return end

    local VT,  dims    = self.VT,           self.model_dims
    local off, mscale  = self.model_offset, self.model_scale
    local sx,  sy      = (VT.w / max(dims.w, 1))*mscale.x, (VT.h / max(dims.h, 1))*mscale.y

    LG.setShader()
    LG.setColor(1, 1, 1, 1)
    LG.draw(mesh, off.x, off.y, 0, sx, sy)
end

-------------------------------------------------------
--- draw
-------------------------------------------------------
function Chara:draw()
    if not self.states.visible then return end
    if not self.model then return end

    push_draw_trans(self)
    if   self.draw_mesh and self.mesh_draw_idx > 0 then self:draw_mesh_model()
    else self:draw_model() end
    LG.pop()

    enqueue_drawable(self.t_drawable, self)
    for _, v in pairs(self.children) do v:draw() end
    self:bound_me()
end

end
