local TabUtils    = require("HMfns.utils.table_utils")
local C, Render   = require("HMfns.animate.color.color_const"), require("HMfns.systems.render")
local ShaderUtils  = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local contains, enqueue_drawable = TabUtils.contains, Render.enqueue_drawable
local cos, sin = math.cos, math.sin
local Y, N = true, false

local T_ch = { "visual", "shadow" }

--- Helper: _shader_visible
local function _shader_visible(st) return (not st.shader_visible) or st.shader_visible.is end

return function (Pawn)
--------------------------------------------------
--- Draw
--------------------------------------------------
--- Helper: init ss 
function Pawn:_init_ss() return ShaderUtils.init_ss(self) end

--- Helper: _sync child draw state 
local function _sync_child_draw_state(self, alpha)
    local ch, VT = self.children, self.VT
    alpha = alpha or self.draw_alpha
    for _, v in pairs(ch) do
        if v.VT then v.VT.scale = VT.scale end
        v.draw_scale_x,  v.draw_scale_y   = self.draw_scale_x or 1,    self.draw_scale_y or 1
        v.draw_anchor_x, v.draw_anchor_y  = self.draw_anchor_x or 0.5, self.draw_anchor_y or 0.5
        v.draw_alpha = alpha
    end
end

--------------------------------------------------
--- Helper: pawn visual tint
--------------------------------------------------
local function _visual_tint(self, alpha)
    local tint = self.params and self.params.visual_tint
    if not tint then return { 1, 1, 1, alpha } end
    return { tint[1] or 1, tint[2] or 1, tint[3] or 1, (tint[4] or 1)*alpha }
end

--- Helper: cast shadow draw state
local function _cast_shadow_draw_state(self, obj, cfg)
    local contact_x = self.ground_contact_x or obj.draw_anchor_x or 0.5
    local contact_y = self.ground_contact_y or obj.draw_anchor_y or 1
    return { draw_scale_x  = (obj.draw_scale_x or 1) * (cfg.scale_x or 1),    draw_scale_y  = (obj.draw_scale_y or 1) * (cfg.scale_y or 1),
        draw_anchor_x      = contact_x,                                       draw_anchor_y = contact_y,
        draw_offset_x      = (obj.draw_offset_x or 0) + (cfg.offset_x or 0),  draw_offset_y = (obj.draw_offset_y or 0) + (cfg.offset_y or 0),
        draw_shear_x       = cfg.shear_x or 0,                                draw_shear_y  = cfg.shear_y or 0,
        draw_alpha         = obj.draw_alpha }
end

--- Helper: draw cast shadow
function Pawn:_draw_cast_shadow()
    local gm, ch, cfg = self.gm, self.children, self.cast_shadow
    if not cfg or not cfg.enabled or gm:is_shadow_off() then return end

    local shadow = ch.shadow or ch.visual;   if not shadow then return end
    _sync_child_draw_state(self, (self.draw_alpha or 1) * (cfg.alpha or 1))

    local draw_state = _cast_shadow_draw_state(self, shadow, cfg)
    shadow:draw_shader(self.template_shader, cfg.height, self.args.send2fs, nil, nil, nil, nil, nil, nil, nil, N, draw_state)
end

--- Helper: draw shadow
function Pawn:_draw_shadow()
    local gm, st, ch  = self.gm, self.states, self.children
    local shadow      = ch.shadow or ch.visual;   if not shadow or gm:is_shadow_off() then return end
    local sh          = self.shadow_heights or {}

    _sync_child_draw_state(self)

    self.shadow_height  = sh.idle or 0.05
    if     st.drag.is  then self.shadow_height = sh.active or 0.15
    elseif st.hover.is then self.shadow_height = sh.hover or 0.10 end
    shadow.tilt_shadow  = self.tilt_shadow
    shadow:draw_shader(self.template_shader, self.shadow_height, self.args.send2fs)
end

--- Helper: draw children
function Pawn:_draw_children()
    local ch,   visual  = self.children, self.children.visual;  if not visual then return end
    local prev, alpha   = { LG.getColor() }, self.draw_alpha or 1
    local tint          = self.params and self.params.visual_tint
    
    _sync_child_draw_state(self, alpha)
    if tint then visual:draw(_visual_tint(self, alpha))
    elseif _shader_visible(self.states) then visual:draw_shader(self.template_shader, nil, self.args.send2fs)
    else visual:draw() end

    for k, v in pairs(ch) do if not contains(T_ch, k) then v:draw() end end
    LG.setColor(prev[1], prev[2], prev[3], prev[4])
end

--- Helper: init tilt var 
function Pawn:_init_tilt_var(st, _tf)
    local gm,  TV    = self.gm, self.tilt_var
    local now, cpos  = gm._T.real_s, gm.CTRL.cursor_position

    if st.hover.is and self._update_tilt then self:_update_tilt(TV, cpos, self.hover_offset, _tf); return end
    
    local _tilt = self.idle_tilt;     if not _tilt then return end

    local VT, RT      = self.VT, gm._room.T
    local tilt_angle  = now * (1.56 + (self.ID / 1.14) % 1) + self.ID / 1.35
    TV.mx   = (0.5 + 0.5*_tilt*cos(tilt_angle)) * VT.w + VT.x + RT.x
    TV.my   = (0.5 + 0.5*_tilt*sin(tilt_angle)) * VT.h + VT.y + RT.y
    TV.amt  = _tilt*(0.5 + cos(tilt_angle))*_tf
end

--_________________________________________
-- main: draw 
--_________________________________________
function Pawn:draw()
    local gm, st = self.gm, self.states
    if not st.visible then return end

    self:_init_ss()
    if not st.hide_shadow.is then 
        if not st.hide_cast.is then self:_draw_cast_shadow() end;
        self:_draw_shadow()
    end
    
    self:_init_tilt_var(st, 0.2)
    self:_draw_children()

    enqueue_drawable(gm.t_drawable, self)
    self:bound_me()
end

end
