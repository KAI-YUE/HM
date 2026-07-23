local ShaderUtils = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local LTP = LG.transformPoint
local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_sp_uniform    = ShaderUtils.send_sp_uniform

local min, max = math.min, math.max

local Y, N = true, false

local M = {}

-----------------------------
--- apply
----------------------------------
--- Helper: _paint_cfg
local function _paint_cfg(self, shader_name)
    local paint = self.config and self.config.paint
    if type(paint) ~= "table" then return {} end
    if M.paint_shader(paint) ~= shader_name then return {} end
    return paint
end

--- Helper: _shader_payload
local function _shader_payload(self) local now = self._T.real_s; return { now/30 + (self.VT.r or 0), now, self.ID }end

--- Helper: _screen_box
local function _screen_box(box)
    local x0,  y0   = LTP(box.x, box.y)
    local x1,  y1   = LTP(box.x + box.w, box.y)
    local x2,  y2   = LTP(box.x, box.y + box.h)
    local x3,  y3   = LTP(box.x + box.w, box.y + box.h)

    local sx0, sy0  = min(x0, x1, x2, x3), min(y0, y1, y2, y3)
    local sx1, sy1  = max(x0, x1, x2, x3), max(y0, y1, y2, y3)
    return { sx0, sy0, max(sx1 - sx0, 1),  max(sy1 - sy0, 1) }
end

-----------------------------
--- gradient uniforms
-----------------------------
--- Helper: _send_gradient_uniforms
local function _send_gradient_uniforms(shader, cfg)
    send_sp_uniform(shader, "gradient_color_0", cfg.color0 or cfg.c0 or { 1, 1, 1, 1 })
    send_sp_uniform(shader, "gradient_color_1", cfg.color1 or cfg.c1 or { 197/255, 1, 80/255, 1 })
    send_sp_uniform(shader, "gradient_a",       cfg.a or cfg.gradient_a or { 0.10, 0.10 })
    send_sp_uniform(shader, "gradient_b",       cfg.b or cfg.gradient_b or { 1.00, 1.00 })
    send_sp_uniform(shader, "gradient_noise",   cfg.noise or cfg.gradient_noise or 1/255)
end

--- Helper: _send_paint_uniforms
local function _send_paint_uniforms(shader, self, shader_name, box)
    local cfg = _paint_cfg(self, shader_name)

    send_sp_uniform(shader, "wave_px",    cfg.wave_px or 1.4)
    send_sp_uniform(shader, "feather_px", cfg.feather_px or 0.02)
    send_sp_uniform(shader, "seed",       cfg.seed or 0)
    send_sp_uniform(shader, "speed",      cfg.speed or 1)
    send_sp_uniform(shader, "speed_factor", cfg.speed_factor or cfg.time_scale or 1)
    send_sp_uniform(shader, "wobble",     cfg.wobble or 0.5)
    send_sp_uniform(shader, "bleed",      cfg.bleed or 0.5)
    send_sp_uniform(shader, "sprite_smooth_radius",    cfg.sprite_smooth_radius or cfg.smooth_radius or 0.75)
    send_sp_uniform(shader, "sprite_smooth_strength",  cfg.sprite_smooth_strength or cfg.smooth_strength or 1.0)
    send_sp_uniform(shader, "sprite_smooth_threshold", cfg.sprite_smooth_threshold or cfg.smooth_threshold or 0.5)
    _send_gradient_uniforms(shader, cfg)
    if not box then return end

    local cx, cy = box.x + 0.5 * box.w, box.y + 0.5 * box.h
    local sx0, sy0 = LTP(cx, cy)
    local sx1, sy1 = LTP(cx + 1, cy)
    local sx2, sy2 = LTP(cx, cy + 1)

    send_sp_uniform(shader, "rect",   { sx0, sy0, box.w, box.h })
    send_sp_uniform(shader, "x_axis", { sx1 - sx0, sy1 - sy0 })
    send_sp_uniform(shader, "y_axis", { sx2 - sx0, sy2 - sy0 })
end

---____________________________
--- main: apply
---______________________________________
function M.apply(self, shader_name, quad, shadow, box, hover_elapsed)
    local gm, rcfg = self.gm, self.rcfg
    local shader   = gm.t_shaders[shader_name];    if not shader or not quad then return end

    local now         = self._T.real_s or 0
    local x, y, w, h  = quad:getViewport()
    local img         = self.sprite_img
    local scale       = rcfg.s_canvas * rcfg.tile_scale * rcfg.tile_size
    local cpos        = self.Ctrl.cursor_position or { x = 0, y = 0 }

    send_base_uniforms(shader, {
        mouse_screen_pos     = { cpos.x * scale, cpos.y * scale },
        screen_scale         = scale,
        hovering             = hover_elapsed(self),
        hover_tilt           = 0,
        position_shader_mode = 0,
        fx_mask              = self.fx_mask or 0,
        time                 = now,
        tex_details          = { x, y, w, h },
        image_details        = { img:getWidth(), img:getHeight() },
        shadow               = not not shadow,
    })

    send_sp_uniform(shader, shader_name, _shader_payload(self))
    send_sp_uniform(shader, "fx_mask_dir", self.fx_mask_dir or 1)

    local wipe_rect = { 0, 0, 1, 1 }
    if box then wipe_rect = _screen_box(box) end

    send_sp_uniform(shader, "wipe_rect", wipe_rect)
    send_sp_uniform(shader, "generic", { 0, now, self.ID or 0 })
    _send_paint_uniforms(shader, self, shader_name, box)

    local old_shader = LG.getShader()
    LG.setShader(shader)
    return Y, old_shader
end

---____________________________
--- main: paint_shader
---______________________________________
function M.paint_shader(paint)
    if type(paint) == "string" then return paint end
    if type(paint) ~= "table"  then return end
    return paint.shader or paint[1]
end

---____________________________
--- main: sprite_shader
---______________________________________
function M.sprite_shader(self, hover_key)
    local cfg = self.config
    local st = self.states
    local active = st and ((st.hover and st.hover.is) or (st.focus and st.focus.is))
    if active and cfg[hover_key] then return cfg[hover_key] end
    return M.paint_shader(cfg.paint)
end

---____________________________
--- main: clear
---______________________________________
function M.clear(applied, old_shader) if applied then LG.setShader(old_shader) end end

return M
