local C, CUtils    = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local Render       = require("HMfns.systems.render")
local ShaderUtils   = require("HMEng.visual.shader_utils")
local LG           = love.graphics

local tint_with_alpha   = CUtils.tint_with_alpha 
local push_draw_trans   = Render.push_actor_draw_transform
local enqueue_drawable  = Render.enqueue_drawable

local cw    = C.WHITE
local Y, N  = true, false

--- Helper: _render_scale
local function _render_scale(self, width_scale, height_scale) if self.lock_wh_ratio == N then return width_scale, height_scale else return width_scale, width_scale end  end

return function (Spritor)
---------------------------------------------------------
--- Define draw steps
---------------------------------------------------------
function Spritor:define_draw_steps(steps) return ShaderUtils.define_draw_steps(self, steps) end

---------------------------------------------------------
--- handle shader
---------------------------------------------------------
function Spritor:handle_shader(h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)
    return ShaderUtils.handle_shader(self, { send_shader_uniform = Y }, h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)
end

---------------------------------------------------------
--- draw shader
---------------------------------------------------------
function Spritor:draw_shader(_shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow, draw_state)
    return ShaderUtils.draw_shader(self, {
        get_tilt_shadow = function(obj, ctx) return ctx.tilt_shadow or obj.tilt_shadow end,
    }, _shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow, draw_state)
end

-------------------------------------------------------
--- Draw self
-------------------------------------------------------
--- Helper: _render
function Spritor:_render()
    local VT, T  = self.VT, self.T
    local sx, sy = _render_scale(self, VT.w / T.w, VT.h / T.h)
    LG.draw(self.img, self.quad, 0, 0, 0, sx, sy)
end

--- Helper: draw local 
function Spritor:draw_local(overlay, width, height)
    if not self.states.visible then return end
    local qw, qh = self.qw, self.qh
    local w, h   = width or qw, height or qh
    local sx, sy = _render_scale(self, w / qw, h / qh)
    LG.setColor(tint_with_alpha(overlay or cw, self.draw_alpha))
    LG.draw(self.img, self.quad, 0, 0, 0, sx, sy)
end

--- Helper: draw shared local 
function Spritor:draw_shader_local(_shader, _send, overlay, _draw_major, width, height)
    local shader = self.t_shaders and self.t_shaders[_shader]
    if not shader then return self:draw_local(overlay, width, height) end

    local draw_major = _draw_major or self.role.draw_major or self
    self:handle_shader(nil, _send, true, _shader, nil, nil, draw_major)
    if shader:hasUniform("fx_mask") then shader:send("fx_mask", 0) end

    local old_shader = LG.getShader()
    LG.setShader(shader)
    self:draw_local(overlay, width, height)
    LG.setShader(old_shader)
end

--- Helper: pixel dims
local function _pixel_dims(self, draw_state)
    local VT, rcfg = self.VT, self.rcfg
    local norm = rcfg.tile_scale * rcfg.tile_size
    local ds = draw_state or self
    local sx = (VT.scale or 1) * (ds.draw_scale_x or 1)
    local sy = (VT.scale or 1) * (ds.draw_scale_y or 1)
    return norm * VT.w * sx, norm * VT.h * sy
end

--- Helper: draw with lens 
local function _draw_with_lens(self, overlay, ctx)
    local VT, lens            = self.VT, self.lens
    local Vw, Vh              = VT.w, VT.h
    local draw_state          = ctx and ctx.draw_state
    local canvas_w, canvas_h  = _pixel_dims(self, draw_state)
    lens:resize(canvas_w, canvas_h)
    local sx, sy = _render_scale(self, lens.width / self.qw, lens.height / self.qh)

    LG.setColor(tint_with_alpha(overlay or cw, self.draw_alpha))
    lens:draw(function() LG.draw(self.img, self.quad, 0, 0, 0, sx, sy) end)

    push_draw_trans(self, nil, nil, nil, draw_state)
    LG.setColor(cw)
    lens:render(0, 0, Vw / lens.width, Vh / lens.height)
    LG.pop()
end

---___________________________
--- Main: draw itself
---___________________________
function Spritor:draw_self(overlay, ctx)
    if not self.states.visible then return end
    local draw_state = ctx and ctx.draw_state
    if self.lens then _draw_with_lens(self, overlay, ctx)
    else
        push_draw_trans(self, nil, nil, nil, draw_state)
        local VT = self.VT;                         local Vw, Vh = VT.w, VT.h

        LG.scale(Vw/self.qw, Vh/self.qh);           LG.setColor(tint_with_alpha(overlay or cw, self.draw_alpha))
        self:_render();                             LG.pop()
    end
    enqueue_drawable(self.t_drawable, self);    self:bound_me()
end

-------------------------------------------------------
--- Draw
-------------------------------------------------------
function Spritor:draw(overlay)
    if not self.states.visible then return end
    if ShaderUtils.run_draw_steps(self) then
    else self:draw_self(overlay) end

    enqueue_drawable(self.t_drawable, self)
    for k, v in pairs(self.children) do if k ~= "h_popup" then v:draw() end end
    self:bound_me()
end

end
