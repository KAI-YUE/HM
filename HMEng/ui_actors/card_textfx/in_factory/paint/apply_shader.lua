local Layout      = require("HMEng.ui_actors.card_textfx.in_factory.layout")
local ShaderUtils = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local rand = math.random
local cos, max, min, sin = math.cos, math.max, math.min, math.sin
local send_uniform  = ShaderUtils.send_sp_uniform

local Y, N = true, false

local ApplyShader = {}

-----------------------------
--- Apply text bg shader
----------------------------------
--- Helper: paint bleed seed
local function _paint_seed(cfg) if not cfg then return 0 end; return cfg.seed or 0 end

--- Helper: paint bleed
local function _paint_bleed(cfg)
    if not cfg then return 0.5 end
    if cfg.bleed ~= nil then return cfg.bleed end
    return 0.5
end

--- Helper: paint wobble
local function _paint_wobble(cfg) if not cfg then return 0.5 end; if cfg.wobble ~= nil then return cfg.wobble end; return 0.5 end

--- Helper: send shared paint edge uniforms
local function _send_paint_uniforms(shader, cfg, rect, x_axis, y_axis)
    cfg = cfg or {}
    local wave_px, feather_px = cfg.wave_px or 1.4, cfg.feather_px or 0.02
    local wobble, bleed = _paint_wobble(cfg), _paint_bleed(cfg)

    send_uniform(shader, "rect",       rect)
    send_uniform(shader, "x_axis",     x_axis)
    send_uniform(shader, "y_axis",     y_axis)
    send_uniform(shader, "wave_px",    wave_px)
    send_uniform(shader, "feather_px", feather_px)
    send_uniform(shader, "seed",       _paint_seed(cfg))
    send_uniform(shader, "wobble",     wobble)
    send_uniform(shader, "bleed",      bleed)

    local bleed_expand = shader:hasUniform("bleed") and bleed or 0
    return max(1, wave_px, wave_px*2.5*bleed_expand*wobble, feather_px)
end

function ApplyShader.apply_text_bg_shader(ctx, box, override_cfg)
    local bg, shader_name
    bg, shader_name = override_cfg, override_cfg.shader;
    if shader_name == N then return end

    local shader = ctx.gm.t_shaders[shader_name];      if not shader then return end

    local cx,  cy   = box.x + 0.5*box.w, box.y + 0.5*box.h
    local cr,  sr   = cos(box.r or 0), sin(box.r or 0)
    local sx0, sy0  = LG.transformPoint(cx, cy)
    local sx1, sy1  = LG.transformPoint(cx + cr, cy + sr)
    local sx2, sy2  = LG.transformPoint(cx - sr, cy + cr)
    local x_axis, y_axis = { sx1 - sx0, sy1 - sy0 }, { sx2 - sx0, sy2 - sy0 }
    local expand    = _send_paint_uniforms(shader, bg, { sx0, sy0, box.w, box.h }, x_axis, y_axis)

    local fx_mask = ctx[bg.fx_mask_ref or "text_bg_fx_mask"] or 0
    local now      = ctx.gm._T.real_s or 0
    ShaderUtils.send_base_uniforms(shader, {
        fx_mask       = max(0, min(fx_mask, 1)),
        time          = now,
        tex_details   = { 0, 0, box.w, box.h },
        image_details = { box.w, box.h },
        shadow        = N,
    })
    send_uniform(shader, "fx_mask_dir", ctx[bg.fx_mask_dir_ref or "fx_mask_dir"] or bg.fx_mask_dir or 1)
    send_uniform(shader, "light_sweep", ctx[bg.light_sweep_ref or "light_sweep"] or 0)
    send_uniform(shader, "light_sweep_brightness", ctx[bg.light_sweep_brightness_ref or "light_sweep_brightness"] or bg.light_sweep_brightness or 0)
    send_uniform(shader, "generic", { 0, now, ctx.ID or 0 })

    local old_shader = LG.getShader()
    LG.setShader(shader)
    return Y, old_shader, expand
end

return ApplyShader
