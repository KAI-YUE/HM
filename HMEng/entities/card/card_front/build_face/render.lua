local Render, C   = require("HMfns.systems.render"), require("HMfns.animate.color.color_const")
local ShaderUtils  = require("HMEng.visual.shader_utils")
local LG = love.graphics

local push_draw_trans  = Render.push_actor_draw_transform
local enqueue_drawable = Render.enqueue_drawable
local abs     = math.abs

local cw, cc  = C.WHITE, C.CLEAR
local Y, N    = true, false

return function (CardFront)
---------------------------------------------------------
--- draw shader
---------------------------------------------------------
-- Helper: handler shader
function CardFront:handle_shader(h, _send, _no_tilt, _shader, custom_shader,  tilt_shadow, _draw_major)
    return ShaderUtils.handle_shader(self, {
        fx_mask_color_default = cc,
        send_shader_uniform   = Y,
        hovering_func = function(_, draw_major) local st = draw_major.states; return ((st.hover and st.hover.is) or (st.drag and st.drag.is)) and 1 or 0; end,
    }, h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)
end

--________________________________________________
-- Main: draw shader 
--_______________________________________________ 
function CardFront:draw_shader(_shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
    return ShaderUtils.draw_shader(self, {
        prepare = function(obj, ctx)  if not ctx.draw_major.states.shader_visible.is then ctx.result = obj:draw_self(); return N; end end,
        draw_with_shader = function(obj) obj:draw_self() end,
    }, _shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
end

-------------------------------------------------------
--- Draw
-------------------------------------------------------
function CardFront:draw_self()
    if not self.states.visible then return end
    
    push_draw_trans(self)
    local T, VT = self.T, self.VT;              local Vw, Vh = VT.w, VT.h 

    LG.scale(Vw/T.w, Vh/T.h);                   LG.setColor(cw)
    self:_render();                             LG.pop()                        
    enqueue_drawable(self.t_drawable, self);    self:bound_me()
end

------------------------------------------
--- draw local 
------------------------------------------
function CardFront:draw_local(width, height)
    if not self.states.visible then return end
    if self.face_dirty then self:_rebuild_face_canvas() end

    local fw, fh = self.face_canvas:getWidth(), self.face_canvas:getHeight()
    local w,  h  = width or self.T.w,  height or self.T.h
    LG.setColor(cw)
    LG.draw(self.face_canvas, 0, 0, 0, w/fw, h/fh)
end

------------------------------------------
--- draw shared local 
------------------------------------------
function CardFront:draw_shader_local(_shader, ss, _draw_major, width, height)
    local shader = self.t_shaders and self.t_shaders[_shader]
    if not shader then return self:draw_local(width, height) end

    local draw_major = _draw_major or self.role.draw_major or self
    self:handle_shader(nil, ss, true, _shader, nil, nil, draw_major)
    if shader:hasUniform("fx_mask") then shader:send("fx_mask", 0) end

    local old_shader = LG.getShader()
    LG.setShader(shader)
    self:draw_local(width, height)
    LG.setShader(old_shader)
end

----------------------------------
--- draw suit shader 
----------------------------------
function CardFront:draw_suit_shader(ss, h)
    local _draw_major  = self.role.draw_major or self
    if not _draw_major.states.shader_visible.is then return self:draw_self() end
    
    local suit_visible = _draw_major.states.suit_shader_visible
    local S, VT, sp    =  self.t_shaders, self.VT, _draw_major.shadow_parallax
    local suit_shader  = (suit_visible and not suit_visible.is) and (_draw_major.template_shader or "generic") or self.suit_shader
    self:handle_shader(h, ss, N, suit_shader, N, N, _draw_major)

    LG.setShader(S[suit_shader]);       self:draw_self()
    LG.setShader()
end

end
