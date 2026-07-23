local TabUtils  = require("HMfns.utils.table_utils")
local CUtils    = require("HMfns.animate.color.color_utils")
local Render    = require("HMfns.systems.render")
local LG        = love.graphics

local contains          = TabUtils.contains
local tint_with_alpha   = CUtils.tint_with_alpha
local enqueue_drawable  = Render.enqueue_drawable
local push_draw_trans   = Render.push_actor_draw_transform

local max, min = math.max, math.min

local T_ch = { "visual", "shadow" }

local Y, N = true, false

return function (AnimTerrainPawn)
--------------------------------------------------
--- draw
--------------------------------------------------
--- Helper: model scales
local function _model_scales(self)
    local VT,   dims    = self.VT,             self.model_dims
    local sx,   sy      = VT.w/max(dims.w, 1), VT.h/max(dims.h, 1)
    local axis, mscale  = self.model_fit_axis, self.model_scale

    if     axis == "width"                    then sy = sx
    elseif axis == "height"                   then sx = sy
    elseif axis == "min" or axis == "contain" then local s = min(sx, sy); sx, sy = s, s
    elseif axis == "max" or axis == "cover"   then local s = max(sx, sy); sx, sy = s, s end
    return sx*mscale.x, sy*mscale.y
end

--- Helper: draw model pass
local function _draw_model_pass(self, color, alpha, draw_state)
    if not self.model then return end

    local off     = self.model_offset
    local sx, sy  = _model_scales(self)
    local old_shader, old_color = LG.getShader(), { LG.getColor() }

    push_draw_trans(self, nil, nil, nil, draw_state)
    LG.setShader()
    LG.setColor(tint_with_alpha(color, alpha))
    self.model:draw(off.x, off.y, 0, sx, sy)
    LG.pop()

    LG.setShader(old_shader)
    LG.setColor(old_color[1], old_color[2], old_color[3], old_color[4])
end

--- Helper: cast shadow draw state
local function _cast_shadow_draw_state(self, cfg)
    local contact_x = self.ground_contact_x or self.draw_anchor_x or 0.5
    local contact_y = self.ground_contact_y or self.draw_anchor_y or 1
    return {
        draw_scale_x  = (self.draw_scale_x or 1) * (cfg.scale_x or 1),     draw_scale_y = (self.draw_scale_y or 1) * (cfg.scale_y or 1),
        draw_anchor_x = contact_x,                                         draw_anchor_y = contact_y,
        draw_offset_x = (self.draw_offset_x or 0) + (cfg.offset_x or 0),   draw_offset_y = (self.draw_offset_y or 0) + (cfg.offset_y or 0),
        draw_shear_x  = cfg.shear_x or 0,                                  draw_shear_y = cfg.shear_y or 0,
    }
end

--- Helper: _draw_anim_cast_shadow
function AnimTerrainPawn:_draw_anim_cast_shadow()
    local gm, cfg = self.gm, self.cast_shadow
    if not cfg or not cfg.enabled or gm:is_shadow_off() then return end
    _draw_model_pass(self, self.shadow_color, (self.draw_alpha or 1) * (cfg.alpha or 1), _cast_shadow_draw_state(self, cfg))
end

--- Helper: _draw_anim_body
function AnimTerrainPawn:_draw_anim_body()
    _draw_model_pass(self, self.vivid_color, self.draw_alpha or 1, self)
    for k, v in pairs(self.children) do if not contains(T_ch, k) then v:draw() end end
end

--- Helper: hover shadow draw state
local function _hover_shadow_draw_state(self, h)
    local sp, s = self.shadow_parallax or {}, 1 - 0.2*(h or 0)
    return {
        draw_scale_x  = (self.draw_scale_x or 1) * s,                       draw_scale_y = (self.draw_scale_y or 1) * s,
        draw_anchor_x = self.draw_anchor_x or 0.5,                          draw_anchor_y = self.draw_anchor_y or 1,
        draw_offset_x = (self.draw_offset_x or 0) - (sp.x or 0) * (h or 0), draw_offset_y = (self.draw_offset_y or 0) - (sp.y or 0) * (h or 0),
    }
end

--- Helper: _draw_anim_shadow
function AnimTerrainPawn:_draw_anim_shadow()
    local gm, st = self.gm, self.states;        if gm:is_shadow_off() then return end

    local sh            = self.shadow_heights or {}
    self.shadow_height  = sh.idle or 0.05
    if     st.drag.is  then self.shadow_height = sh.active or 0.15
    elseif st.hover.is then self.shadow_height = sh.hover or 0.10 end

    _draw_model_pass(self, self.shadow_color, self.draw_alpha or 1, _hover_shadow_draw_state(self, self.shadow_height))
end

---_______________________________________________
--- main: draw 
---_______________________________________________
function AnimTerrainPawn:draw()
    local gm, st = self.gm, self.states;        if not st.visible or not self.model then return end

    if not st.hide_shadow.is then
        if not st.hide_cast.is then self:_draw_anim_cast_shadow() end
        self:_draw_anim_shadow()
    end

    self:_init_tilt_var(st, 0.2)
    self:_draw_anim_body()

    enqueue_drawable(gm.t_drawable, self)
    self:bound_me()
end

end
