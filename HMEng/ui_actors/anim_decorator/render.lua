local Render    = require("HMfns.systems.render")
local PaintRect = require("HMEng.ui_actors.card_textfx.in_factory.paint.textfx_bg_paint_rect")
local C         = require("HMfns.animate.color.color_const")
local LG        = love.graphics

local max = math.max
local push_draw_trans  = Render.push_actor_draw_transform
local enqueue_drawable = Render.enqueue_drawable

local Y, N = true, false

return function (AnimDecorator)
---____________________________
--- main: draw_model
---______________________________________
function AnimDecorator:draw_model()
    if not self.model then return end

    local VT,  dims    = self.VT,                        self.model_dims
    local off, mscale  = self.model_offset,              self.model_scale
    local sx,  sy      = (VT.w/max(dims.w, 1))*mscale.x, (VT.h/max(dims.h, 1))*mscale.y

    LG.setShader()
    LG.setColor(1, 1, 1, self.draw_alpha or 1)
    self.model:draw(off.x, off.y, 0, sx, sy)
end

---____________________________
--- main: draw_mesh_model
---______________________________________
function AnimDecorator:draw_mesh_model()
    local mesh = self.model_mesh and self.model_mesh[self.mesh_draw_idx];       if not mesh then return end

    local VT, dims, off, mscale = self.VT, self.model_dims, self.model_offset, self.model_scale
    local sx = (VT.w/max(dims.w, 1))*mscale.x
    local sy = (VT.h/max(dims.h, 1))*mscale.y

    LG.setShader()
    LG.setColor(1, 1, 1, self.draw_alpha or 1)
    LG.draw(mesh, off.x, off.y, 0, sx, sy)
end

-----------------------------
--- draw
----------------------------------
--- Helper: _bg_cfg
local function _bg_cfg(self)
    local bg = self.config and (self.config.sprite_bg or self.config.bg);   if not bg then return end

    local out = {}
    for k, v in pairs(bg.paint or bg) do out[k] = v end

    out.color,  out.shadow_color  = bg.fill_color or bg.color or out.color or C.BLACK, bg.shadow_color or out.shadow_color
    out.shadow, out.renderer      = bg.shadow,  bg.renderer or out.renderer
    out.paint_alpha               = bg.paint_alpha or out.paint_alpha

    return bg, out
end

--- Helper: _draw_bg
local function _draw_bg(self)
    local bg, cfg  = _bg_cfg(self);                          if not bg then return end
    local T,  tz   = bg.T or bg, self.rcfg.tile_size
    local box      = { x = (T.x or 0)*tz, y = (T.y or 0)*tz, w = (T.w or self.VT.w)*tz, h = (T.h or self.VT.h)*tz, r = T.r or bg.r or 0 }
    local ctx      = setmetatable({ config = cfg }, { __index = self })
    cfg.shadow     = bg.shadow ~= N
    PaintRect.draw_bleed_layer(ctx, box, cfg, N)
end

---____________________________
--- main: draw
---______________________________________
function AnimDecorator:draw()
    if not self.states.visible then return end
    if not self.model then return end

    push_draw_trans(self)
    LG.scale(1 / self.rcfg.tile_size)
    _draw_bg(self)
    LG.pop()

    push_draw_trans(self)
    if self.draw_mesh and self.mesh_draw_idx > 0 then self:draw_mesh_model()
    else self:draw_model() end
    LG.pop()

    enqueue_drawable(self.t_drawable, self)
    for _, v in pairs(self.children) do v:draw() end
    self:bound_me()
end

end
