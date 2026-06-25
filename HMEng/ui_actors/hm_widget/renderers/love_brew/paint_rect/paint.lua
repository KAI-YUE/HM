local ApplyShader = require("HMEng.ui_actors.card_textfx.in_factory.paint.apply_shader")
local PaintSeeds  = require("HMEng.ui_actors.card_textfx.data.paint_seeds")
local Parallax    = require("HMEng.actors.actor.parallax")
local CUtils      = require("HMfns.animate.color.color_utils")
local C           = require("HMfns.animate.color.color_const")
local TabUtils    = require("HMfns.utils.table_utils")
local LG          = love.graphics

local copy, pick = TabUtils.deep_copy, TabUtils.random_pick
local tint_with_alpha = CUtils.tint_with_alpha

local N = false
local ck = C.BLACK
local tcshadow = tint_with_alpha(ck, 0.3)

local M = {}

-----------------------------
--- paint cfg helpers
-----------------------------
--- Helper: first non nil
local function _first_non_nil(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then return v end
    end
end

--- Helper: paint seed entry
local function _paint_seed_entry(ctx, bg)
    if bg and bg.paint_seed_entry then return bg.paint_seed_entry end
    local cfg = ctx.config
    if cfg and cfg.paint_seed_entry then return cfg.paint_seed_entry end
    return pick(PaintSeeds, ctx.ID)
end

--- Helper: resolve bleed layer cfg
local function _resolve_bleed_layer_cfg(ctx, bg)
    local seed_entry, layer = _paint_seed_entry(ctx, bg), copy(bg)
    layer.shader = layer.shader or "_1_watercolor_edge"
    layer.seed   = layer.seed or seed_entry.seed
    layer.wobble = _first_non_nil(layer.wobble, seed_entry.wobble)
    layer.bleed  = _first_non_nil(layer.bleed,  seed_entry.bleed)
    layer.x_mul  = _first_non_nil(layer.x_mul,  seed_entry.x_mul)
    layer.y_mul  = _first_non_nil(layer.y_mul,  seed_entry.y_mul)
    layer.w_mul  = _first_non_nil(layer.w_mul,  seed_entry.w_mul)
    layer.h_mul  = _first_non_nil(layer.h_mul,  seed_entry.h_mul)
    layer.x      = _first_non_nil(layer.x,      layer.ox, seed_entry.x, seed_entry.ox)
    layer.y      = _first_non_nil(layer.y,      layer.oy, seed_entry.y, seed_entry.oy)
    layer.w      = _first_non_nil(layer.w,      layer.ow, seed_entry.w, seed_entry.ow)
    layer.h      = _first_non_nil(layer.h,      layer.oh, seed_entry.h, seed_entry.oh)
    return layer
end

local bleed_layer_sync_keys = {
    "shader", "fx_mask_ref", "fx_mask_dir_ref", "light_sweep_ref", "light_sweep_brightness_ref",
    "slot_enter_shader", "wave_px", "feather_px", "seed", "wobble", "bleed", "widget_dist",
}

--- Helper: sync bleed layer cfg
local function _sync_bleed_layer_cfg(layer, bg)
    for _, key in ipairs(bleed_layer_sync_keys) do
        if bg[key] ~= nil then layer[key] = bg[key] end
    end
    layer.color        = bg.color
    layer.shadow       = bg.shadow
    layer.shadow_color = bg.shadow_color
end

--- Helper: bleed layer cfg
local function _bleed_layer_cfg(ctx, bg)
    if not bg then return end
    local cfg = ctx.config
    if not cfg then return _resolve_bleed_layer_cfg(ctx, bg) end

    cfg._paint_bleed_src = cfg._paint_bleed_src or bg
    if cfg._paint_bleed_layer_cfg and cfg._paint_bleed_src == bg then
        _sync_bleed_layer_cfg(cfg._paint_bleed_layer_cfg, bg)
        return cfg._paint_bleed_layer_cfg
    end
    cfg._paint_bleed_src = bg
    cfg._paint_bleed_layer_cfg = _resolve_bleed_layer_cfg(ctx, bg)
    return cfg._paint_bleed_layer_cfg
end

-----------------------------
--- draw helpers
-----------------------------
--- Helper: with paint alpha
local function _with_paint_alpha(ctx, color)
    local cfg = ctx and ctx.config or {}
    local a   = cfg.paint_alpha
    if a == nil then a = cfg.textfx_alpha or 1 end
    a = a * (cfg.slot_enter_alpha == nil and 1 or cfg.slot_enter_alpha)
    a = a * ((ctx and ctx.draw_alpha) or 1)
    a = math.max(0, math.min(a, 1))
    color = color or ck
    return { color[1], color[2], color[3], (color[4] or 1)*a }
end

--- Helper: parallax shadow offset
local function _parallax_shadow_offset(ctx, box, dist)
    local sp, rcfg, cfg = ctx.shadow_parallax or {}, ctx.rcfg or {}, ctx.config or {}
    local tz, spx = ((cfg.renderer == "paint_rect" or cfg.paint_rect_renderer) and 1) or rcfg.tile_size, sp.x or 0

    if ctx.T and ctx._room then spx = Parallax.shadow_x(ctx.gm, ctx._room.T, ctx.T) end
    return -spx*dist/tz, -((sp.y or 0.1)*dist/tz)
end

--- Helper: bleed box
local function _bleed_box(box, cfg)
    return {
        x = (cfg.x_mul and box.x*cfg.x_mul or box.x) + (cfg.x or cfg.ox or 0),
        y = (cfg.y_mul and box.y*cfg.y_mul or box.y) + (cfg.y or cfg.oy or 0),
        w = (cfg.w_mul and box.w*cfg.w_mul or box.w) + (cfg.w or cfg.ow or 0),
        h = (cfg.h_mul and box.h*cfg.h_mul or box.h) + (cfg.h or cfg.oh or 0),
        r = box.r,
    }
end

-----------------------------
--- draw_paint_rect
-----------------------------
---____________________________
--- main: draw_paint_rect
---____________________________
function M.draw_paint_rect(ctx, box, cfg, require_shader, color)
    local shader_on, old_shader, expand = ApplyShader.apply_text_bg_shader(ctx, box, cfg)
    if require_shader and not shader_on then return end
    expand = shader_on and expand or 0

    LG.setColor(_with_paint_alpha(ctx, color))
    LG.push()
    LG.translate(box.x + 0.5*box.w, box.y + 0.5*box.h)
    LG.rotate(box.r or 0)
    LG.rectangle("fill", -0.5*box.w - expand, -0.5*box.h - expand, box.w + 2*expand, box.h + 2*expand)
    LG.pop()
    if shader_on then LG.setShader(old_shader) end
end

---____________________________
--- main: draw_bleed_layer
---____________________________
function M.draw_bleed_layer(ctx, box, bg, require_shader, opts)
    opts = opts or {}
    local bleed_cfg    = _bleed_layer_cfg(ctx, bg); if not bleed_cfg then return end
    local bleed_box    = _bleed_box(box, bleed_cfg)
    local needs_shader = require_shader ~= N

    local dist   = bleed_cfg.widget_dist or 2.55
    local sx, sy = _parallax_shadow_offset(ctx, bleed_box, dist)
    local shadow = bleed_cfg.shadow ~= N and ctx.config and ctx.config.shadow

    if not shadow then return opts.shadow_only and nil or M.draw_paint_rect(ctx, bleed_box, bleed_cfg, needs_shader, bleed_cfg.color or ck) end

    local shadow_box = { x = bleed_box.x + sx, y = bleed_box.y + sy, w = bleed_box.w, h = bleed_box.h, r = bleed_box.r }
    if not opts.skip_shadow then M.draw_paint_rect(ctx, shadow_box, bleed_cfg, needs_shader, bleed_cfg.shadow_color or tcshadow) end
    if opts.shadow_only then return end
    M.draw_paint_rect(ctx, bleed_box, bleed_cfg, needs_shader, bleed_cfg.color or ck)
end

return M
