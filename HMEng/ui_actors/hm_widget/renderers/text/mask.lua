local ShaderUtils = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_uniform = ShaderUtils.send_sp_uniform

local Y, N = true, false

local M = {}

--- Helper: _screen_box
local function _screen_box(box)
    local x0, y0 = LG.transformPoint(box.x,         box.y)
    local x1, y1 = LG.transformPoint(box.x + box.w, box.y)
    local x2, y2 = LG.transformPoint(box.x,         box.y + box.h)
    local x3, y3 = LG.transformPoint(box.x + box.w, box.y + box.h)
    local sx0, sy0 = math.min(x0, x1, x2, x3), math.min(y0, y1, y2, y3)
    local sx1, sy1 = math.max(x0, x1, x2, x3), math.max(y0, y1, y2, y3)
    return sx0, sy0, math.max(sx1 - sx0, 1), math.max(sy1 - sy0, 1)
end

--- main: box
function M.box(self, default_box, text_box)
    local cfg = self.config
    if cfg.text_mask_box == "text" then return text_box end

    local T = cfg.text_mask_T
    if T then
        return {
            x = default_box.x + (T.x or 0),
            y = default_box.y + (T.y or 0),
            w = T.w or default_box.w,
            h = T.h or default_box.h,
        }
    end

    local s = cfg.text_mask_scale
    if s then
        local sx, sy = s.x or s.w or s[1] or 1, s.y or s.h or s[2] or s.x or s.w or s[1] or 1
        return {
            x = default_box.x + 0.5*default_box.w*(1 - sx),
            y = default_box.y + 0.5*default_box.h*(1 - sy),
            w = default_box.w*sx,
            h = default_box.h*sy,
        }
    end

    return default_box
end

--- main: apply
function M.apply(self, box)
    local cfg = self.config
    local shader_name = cfg.text_mask_shader;       if not shader_name then return end
    local fx_mask = self[cfg.text_mask_ref or "fx_mask"] or 0
    local light_sweep = self[cfg.text_light_sweep_ref or "light_sweep"] or 0
    if fx_mask <= 0.001 and light_sweep <= 0.001 then return end

    local shader = self.gm.t_shaders and self.gm.t_shaders[shader_name];      if not shader then return end
    local sx0, sy0, sw, sh = _screen_box(box)
    local now = self.gm._T.real_s or 0
    local old_shader = LG.getShader()

    send_base_uniforms(shader, {
        fx_mask       = math.max(0, math.min(fx_mask, 1)),
        time          = now,
        tex_details   = { 0, 0, sw, sh },
        image_details = { sw, sh },
        shadow        = N,
    })
    send_uniform(shader, "fx_mask_dir", self[cfg.text_mask_dir_ref or "fx_mask_dir"] or cfg.text_mask_dir or 1)
    send_uniform(shader, "light_sweep", light_sweep)
    send_uniform(shader, "light_sweep_brightness", self[cfg.text_light_sweep_brightness_ref or "light_sweep_brightness"] or cfg.text_light_sweep_brightness or 0)
    send_uniform(shader, "wipe_rect", { sx0, sy0, sw, sh })
    send_uniform(shader, "generic", { 0, now, self.ID or 0 })
    LG.setShader(shader)
    return Y, old_shader
end

return M
