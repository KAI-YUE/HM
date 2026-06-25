local ShaderUtils = require("HMEng.visual.shader_utils")
local C          = require("HMfns.animate.color.color_const")
local Render     = require("HMfns.systems.render")

local abs, max, floor = math.abs, math.max, math.floor
local Ted_shaders     = { "foil", "glow" }

local cw, cc = C.WHITE, C.CLEAR
local Y, N   = true, false

local LG = love.graphics

return function (Card)
--- Helper: _shader_visible
local function _shader_visible(st) return (not st.shader_visible) or st.shader_visible.is end

--- Helper: fx masked active
function Card:_fx_mask_active() return abs(self and self.fx_mask or 0) > 0.001 end

--- Helper: joint canvas dims 
function Card:_joint_canvas_dims(ctemplate, front)
    local tw, th = (ctemplate and ctemplate.qw) or 0, (ctemplate and ctemplate.qh) or 0
    local fw, fh = 0, 0
    if front and front._init_face_cache then
        front:_init_face_cache()
        fw, fh = front.fw or 0, front.fh or 0
    end

    return max(1, floor(max(tw, fw) + 0.5)), max(1, floor(max(th, fh) + 0.5))
end

--- Helper: ensure joint canvas 
function Card:_ensure_joint_canvas(width, height)
    local canvas   = self.fx_mask_canvas
    local cw0, ch0 = canvas and canvas:getWidth() or 0, canvas and canvas:getHeight() or 0

    if canvas and cw0 == width and ch0 == height then return canvas end
    canvas = LG.newCanvas(width, height)
    self.fx_mask_canvas = canvas
    return canvas
end

--- Helper: render seal ed joint
function Card:_render_seal_ed_joint(ed, basic, front, ctemplate, _ss, width, height)
    local s_code = "rainbow_edge"

    for _, shader_name in ipairs(Ted_shaders) do
        if not ed or not ed[shader_name] then goto continue end 
        ctemplate:draw_shader_local(shader_name, _ss, nil, self, width, height)
        if basic then front:draw_shader_local(shader_name, _ss, self, width, height) end
        ::continue::
    end

    if ed and ed.test then
        ctemplate:draw_shader_local(s_code, _ss, nil, self, width, height)
        if basic then front:draw_shader_local(s_code, _ss, self, width, height) end
    end
end

--- Helper: canvas wo shader 
function Card:_canvas_wo_shader(canvas, T, width, height)
    Render.push_actor_draw_transform(self)
    LG.setColor(cw)
    LG.draw(canvas, 0, 0, 0, T.w / width, T.h / height)
    LG.pop()
end

--- Helper: draw masked joint canvas 
function Card:_draw_masked_joint_canvas(canvas, width, height)
    local gm, args   = self.gm, self.args
    local T, shader  = self.T, gm.t_shaders and gm.t_shaders.plain

    if not shader then return self:_canvas_wo_shader(canvas, T, width, height) end

    local dc, cs = self.fx_mask_colors, { cc, cc }
    local time = self._T.real_s % 100 + 10 * (self.ID / 1.1 or 13) % 100
    if dc then cs[1] = dc[1] or cs[1]; cs[2] = dc[2] or cs[2] end

    ShaderUtils.send_base_uniforms(shader, {
        mouse_screen_pos = { 0, 0 },  screen_scale         = 1,               hovering      = 0,
        hover_tilt = 0,               position_shader_mode = 0,               fx_mask       = abs(self.fx_mask or 0),
        time = time,                  tex_details = { 0, 0, width, height },  image_details = { width, height },
        c1 = cs[1],                  c2 = cs[2],                   shadow        = N,
    })

    if shader:hasUniform("plain") then
        local ss = self.args and self.args.send2fs or { 1, 1, 1 }
        shader:send("plain", ss)
    end

    Render.push_actor_draw_transform(self)
    LG.setColor(cw)
    LG.setShader(shader)
    LG.draw(canvas, 0, 0, 0, T.w / width, T.h / height)
    LG.setShader()
    LG.pop()
end

--- Helper: render mask front 
function Card:_render_masked_front(gm, ed, basic, front, ctemplate, _ss)
    local width, height = self:_joint_canvas_dims(ctemplate, front)
    local canvas = self:_ensure_joint_canvas(width, height)
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()

    LG.push()
    LG.origin()
    LG.setCanvas(canvas)
    LG.setShader()
    LG.setColor(cw)
    LG.clear(0, 0, 0, 0)

    if _shader_visible(self.states) then
        ctemplate:draw_shader_local(self.template_shader, _ss, nil, self, width, height)
        if basic then front:draw_shader_local(front.suit_shader, _ss, self, width, height) end
    else
        ctemplate:draw_local(nil, width, height)
        if basic then front:draw_local(width, height) end
    end

    self:_render_seal_ed_joint(ed, basic, front, ctemplate, _ss, width, height)

    LG.pop()
    if old_canvas then LG.setCanvas({ old_canvas, stencil = true }) else LG.setCanvas() end
    LG.setShader(old_shader)
    LG.setColor(cw)

    self:_draw_masked_joint_canvas(canvas, width, height)
end

end
