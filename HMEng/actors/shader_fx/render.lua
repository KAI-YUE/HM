local Render      = require("HMfns.systems.render")
local ShaderUtils  = require("HMEng.visual.shader_utils")
local C, LG       = require("HMfns.animate.color.color_const"), love.graphics

local push_draw_trans  = Render.push_actor_draw_transform
local enqueue_drawable = Render.enqueue_drawable

local max, min = math.max, math.min

local cw   = C.WHITE
local Y, N = true, false

return function (ShaderFX)
---------------------------------------------------------
--- init_ss
---------------------------------------------------------
function ShaderFX:_init_ss()
    local ss = ShaderUtils.init_ss(self, { base = function(obj, _, VT, TV) return max(0, min(1, (obj.shader_tilt or 0.65) + min(3 * (VT.r or 0), 1) + (TV.amt or 0))) end })
    -- ss[4] = nil
    return ss
end

---------------------------------------------------------
--- define draw steps
---------------------------------------------------------
function ShaderFX:define_draw_steps(steps) return ShaderUtils.define_draw_steps(self, steps) end

---------------------------------------------------------
--- handle shader
---------------------------------------------------------
--- Helper: send shader uniforms
local function _send_shader_uniforms(self, _shader)
    local shader, uniforms = self.t_shaders and self.t_shaders[_shader], self.shader_uniforms;       if not (shader and uniforms) then return end
    for name, val in pairs(uniforms) do ShaderUtils.send_sp_uniform(shader, name, val) end
end

function ShaderFX:handle_shader(h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)
    local result = ShaderUtils.handle_shader(self, { send_shader_uniform = Y }, h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)
    _send_shader_uniforms(self, _shader)
    return result
end

---------------------------------------------------------
--- main: draw shader
---------------------------------------------------------
function ShaderFX:draw_shader(_shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
    return ShaderUtils.draw_shader(self, { get_tilt_shadow = function(obj, ctx) return ctx.tilt_shadow or obj.tilt_shadow end },
        _shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
end

-------------------------------------------------------
--- draw self
-------------------------------------------------------
--- Helper: _render 
function ShaderFX:_render()
    local VT, T   = self.VT, self.T
    local Vw, Vh  = VT.w, VT.h
    local w,  h   = T.w, T.h
    LG.draw(self.img, self.quad, 0, 0, 0, Vw/w, Vh/h)
end

---______________________
--- draw self 
---______________________
function ShaderFX:draw_self(overlay)
    if not self.states.visible then return end

    push_draw_trans(self)
    local VT      = self.VT
    local Vw, Vh  = VT.w, VT.h
    local tint    = overlay or cw
    local alpha   = (tint[4] or 1)*(self.draw_alpha or 1)
    tint          = { tint[1], tint[2], tint[3], alpha }

    LG.scale(Vw / self.qw, Vh / self.qh);     LG.setColor(tint)
    self:_render();                           LG.pop()
    enqueue_drawable(self.t_drawable, self);  self:bound_me()
end

-------------------------------------------------------
--- draw
-------------------------------------------------------
function ShaderFX:draw(overlay)
    if not self.states.visible then return end
    if ShaderUtils.run_draw_steps(self) then --  skip for now 
    elseif self.shader_code then self:_init_ss(); self:draw_shader(self.shader_code, nil, self.args.send2fs)
    else                         self:draw_self(overlay) end

    enqueue_drawable(self.t_drawable, self)
    for k, v in pairs(self.children) do if k ~= "h_popup" then v:draw() end end
    self:bound_me()
end

end
