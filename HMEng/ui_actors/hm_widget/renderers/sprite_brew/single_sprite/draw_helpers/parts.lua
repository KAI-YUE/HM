local Color  = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.color")
local Shader = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.shader")

local LG = love.graphics

local M = {}

--- Helper: _hover_like_active
local function _hover_like_active(self)
    local st = self.states;    if not st then return end
    return (st.hover and st.hover.is) or (st.focus and st.focus.is)
end

---____________________________
--- main: has_visible_mask
---______________________________________
function M.has_visible_mask(self, cfg)
    local fc, dc = cfg.fill_color, cfg.sprite_mask_deco_color
    return self.sprite_mask_quad
        and self.sprite_mask_metrics
        and (
            (type(fc) == "table" and (fc[4] or 1) > 0.01)
            or (type(dc) == "table" and (dc[4] or 1) > 0.01)
        )
end

-----------------------------
--- draw_mask
----------------------------------
--- Helper: _mask_box
local function _mask_box(dw, dh, x, y, ofs, sc)
    local mw, mh = dw * (sc.x or 1), dh * (sc.y or 1)
    local mx     = x + 0.5 * (dw - mw) + (ofs.x or 0) * dw
    local my     = y + 0.5 * (dh - mh) + (ofs.y or 0) * dh
    return mx, my, mw, mh
end

--- Helper: _draw_mask_pass
local function _draw_mask_pass(self, img, color, mx, my, mw, mh, dx, dy, shadow, hover_elapsed)
    local MM       = self.sprite_mask_metrics
    local msx, msy = mw/MM.w, mh/MM.h

    local shader_on, old_shader = Shader.apply(
        self,
        _hover_like_active(self) and self.config.hover_mask_shader,
        self.sprite_mask_quad,
        shadow,
        { x = mx + (dx or 0), y = my + (dy or 0), w = mw, h = mh },
        hover_elapsed
    )

    LG.setColor(Color.with_draw_alpha(self, color))
    LG.draw(img, self.sprite_mask_quad, mx + (dx or 0), my + (dy or 0), 0, msx, msy)
    Shader.clear(shader_on, old_shader)
end

---____________________________
--- main: draw_mask
---______________________________________
function M.draw_mask(self, img, x, y, dw, dh, dx, dy, shadow, hover_elapsed)
    local cfg         = self.config
    local deco_color  = not shadow and cfg.sprite_mask_deco_color

    if type(deco_color) == "table" and (deco_color[4] or 1) > 0.01 then
        local ofs,    sc      = cfg.sprite_mask_deco_offset or cfg.sprite_mask_offset or { x = 0, y = 0 }, cfg.sprite_mask_deco_scale or { x = 1, y = 1 }
        local mx, my, mw, mh  = _mask_box(dw, dh, x, y, ofs, sc)
        _draw_mask_pass(self, img, deco_color, mx, my, mw, mh, dx, dy, shadow, hover_elapsed)
    end

    local fc = cfg.fill_color;                         if not (type(fc) == "table" and (fc[4] or 1) > 0.01) then return end
    local mask_color = Color.mask_color(self, shadow); if not (type(mask_color) == "table" and (mask_color[4] or 1) > 0.01) then return end

    local ofs,    sc      = cfg.sprite_mask_offset or { x = 0, y = 0 }, cfg.sprite_mask_scale or { x = 1, y = 1 }
    local mx, my, mw, mh  = _mask_box(dw, dh, x, y, ofs, sc)
    _draw_mask_pass(self, img, mask_color, mx, my, mw, mh, dx, dy, shadow, hover_elapsed)
end

-----------------------------
--- draw_face
----------------------------------
--- Helper: _sprite_flip_scale
local function _sprite_flip_scale(cfg)
    local fx, fy = 1, 1
    if cfg.sprite_flip_x then fx = -1 end
    if cfg.sprite_flip_y then fy = -1 end
    return fx, fy
end

--- Helper: _sprite_rotation
local function _sprite_rotation(self)
    local cfg    = self.config
    local speed  = cfg.sprite_rotate_speed or 0
    if speed == 0 then return cfg.sprite_rotate_phase or 0 end
    return (cfg.sprite_rotate_phase or 0) + (self._T.real_s or 0) * speed
end

---____________________________
--- main: draw_face
---______________________________________
function M.draw_face(self, img, quad, x, y, sx, sy, dx, dy, shadow, hover_elapsed)
    local _, _, qw, qh = quad:getViewport()
    local fx,   fy     = _sprite_flip_scale(self.config)
    local box          = { x = x + (dx or 0), y = y + (dy or 0), w = qw * sx, h = qh * sy }

    local shader_on, old_shader = Shader.apply(
        self,       Shader.sprite_shader(self, "hover_face_shader"),
        quad,       shadow,
        box,        hover_elapsed
    )

    LG.setColor(Color.with_draw_alpha(self, Color.face_color(self, shadow)))
    LG.draw(
        img,                        quad,
        x + (dx or 0) + 0.5*qw*sx,  y + (dy or 0) + 0.5*qh*sy,
        _sprite_rotation(self),
        sx*fx,                      sy * fy,
        0.5*qw,                     0.5 * qh
    )
    Shader.clear(shader_on, old_shader)
end

return M
