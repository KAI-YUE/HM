local StrokeBrush = require("HMEng.visual.stroked_brush")
local C = require("HMfns.animate.color.color_const")

local max, min = math.max, math.min

local cw, ck = C.WHITE, C.BLACK
local Y, N = true, false

local Hint = {}

-----------------------------
--- draw hover hint
----------------------------------
--- Helper: _clamp 
local function _clamp(v, lb, ub)        return min(ub, max(v, lb)) end

--- Helper: _alpha
local function _alpha(ctx)
    local cfg = ctx.config or {}
    local a = cfg.textfx_alpha == nil and 1 or cfg.textfx_alpha
    if a < 0 then return 0 elseif a > 1 then return 1 end
    return a
end

--- Helper: _with_alpha
local function _with_alpha(color, alpha) return { color[1], color[2], color[3], (color[4] or 1)*alpha } end

--- Helper: text hint cfg
local function _text_hint_cfg(ctx)
    local cfg  = ctx.config or {}
    local hint = cfg.text_hint
    if hint == N then return end
    if hint == Y or hint == nil then return {} end
    return hint
end

--- Helper: prepare hint brush
local function _hint_brush(ctx, cache, hint)
    local skey  = "underline"
    local brush = cache.hint_brush;          if brush and brush.config.key == skey then return brush end

    brush = StrokeBrush(ctx.gm, { stroke_key = skey, x = 0, y = hint.stroke_y or 0.78, w = 1, h = 0.06,  rot_ax = 0.5,  rot_ay = 0.5 }, hint.atlas_key)
    cache.hint_brush = brush
    return brush
end

---____________________________
--- main: draw_hover_hint
---______________________________________
function Hint.draw_hover_hint(ctx, cache, x, y, fx_mask)
    if fx_mask == nil then return end
    local hint = _text_hint_cfg(ctx);          if not hint then return end

    local gm,       _shader   = ctx.gm, hint.fx_mask_shader or "_-2_stroke_wipe"
    local fx_mask,  b         = _clamp(fx_mask, 0, 1), cache.bounds or { x = 0, y = 0, w = cache.w, h = cache.h }

    local dx,       dy        = x + b.x,                            y + b.y + 0.3
    local r,        alpha     = cache.r or 0,                       _alpha(ctx)
    local color               = _with_alpha(hint.color or cw, alpha)
    local time,     id        = gm._T.real_s,                        ctx.ID or 0
    local brush,    rcfg      = _hint_brush(ctx, cache, hint),      ctx.rcfg

    local sp,   tz    = ctx.shadow_parallax or {}, rcfg.tile_size
    local dist, _s    = hint.widget_dist or 1.55, (hint.shadow ~= N and ctx.config.shadow)
    local sx,   sy    = -(sp.x or 0)*dist/tz, -(sp.y or 0)*dist/tz

    brush:draw({ gm = gm,    wpx = b.w,                 hpx     = b.h,      dx       = dx,      dy = dy,  r = r,  color = color,
        fx_mask = fx_mask,   fx_mask_shader = _shader,  time     = time,    id       = id,      hide_without_fx_mask_shader = Y,
        shadow = _s,         shadow_color   = _with_alpha(ck, alpha),       shadow_x = sx,      shadow_y = sy,
    })
end

return Hint
