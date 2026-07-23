local ShaderUtils = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_sp_uniform    = ShaderUtils.send_sp_uniform

return function (Wallpaper)
--------------------------------------------------
--- apply shader
--------------------------------------------------
--- Helper: _opt_val
local function _opt_val(opts, key, fallback) local v = opts and opts[key]; if v ~= nil then return v end; return fallback end

---________________________________
--- main: apply shader
---________________________________
function Wallpaper:apply_shader()
    local cfg     = self.config
    local shader  = cfg.shader and self.t_shaders[cfg.shader];      if not (shader and self.quad and self.image) then return end

    local qx, qy, qw, qh = self.quad:getViewport()
    local rw,     rh     = LG.getDimensions()
    local now,    opts   = (self._T.shaders_s) or 0, cfg.shader_opts

    send_base_uniforms(shader, {
        time = now,
        tex_details    = { qx, qy, qw, qh },
        image_details  = self.image_dims or { self.image:getDimensions() },
        blur_severity  = _opt_val(opts, "blur_severity", nil),
        blur_radius    = _opt_val(opts, "blur_radius", _opt_val(opts, "radius", nil)),
        speed_factor   = _opt_val(opts, "speed_factor",  nil),
    })
    
    send_sp_uniform(shader, "_tex_details",  { qx, qy, qw, qh })
    send_sp_uniform(shader, "image_details", self.image_dims or { self.image:getDimensions() })
    send_sp_uniform(shader, "resolution",    { rw, rh })
    send_sp_uniform(shader, "time",          now)
    send_sp_uniform(shader, _opt_val(opts, "field_uniform", cfg.shader), { 0, now, self.ID or 0 })
    send_sp_uniform(shader, "blur_clean_stage",   _opt_val(opts, "blur_clean_stage",   nil))
    send_sp_uniform(shader, "blur_turning_point", _opt_val(opts, "blur_turning_point", nil))
    send_sp_uniform(shader, "blur_peak_point",    _opt_val(opts, "blur_peak_point",    nil))
    send_sp_uniform(shader, "blur_clean_amount",  _opt_val(opts, "blur_clean_amount",  nil))
    send_sp_uniform(shader, "blur_increase_speed", _opt_val(opts, "blur_increase_speed", nil))
    send_sp_uniform(shader, "blur_fall_slowdown", _opt_val(opts, "blur_fall_slowdown", nil))
    send_sp_uniform(shader, "hovering",      0)
    send_sp_uniform(shader, "fx_mask",       0)

    for _, v in ipairs(opts.send or {}) do if v.name then send_sp_uniform(shader, v.name, v.val) end end
    LG.setShader(shader)
    return shader
end

end
