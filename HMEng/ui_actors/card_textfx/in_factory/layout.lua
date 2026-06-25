local TextAlign = require("HMEng.ui_actors.hm_widget.renderers.text.text_align")

local cos, max, min, sin = math.cos, math.max, math.min, math.sin

local Y, N = true, false

local Layout = {}

--- Helper: _first_non_nil
local function _first_non_nil(a, b, c) if a ~= nil then return a elseif b ~= nil then return b else return c end end

---____________________________
--- main: text_visual_box
---______________________________________
function Layout.text_visual_box(ctx, cache, opts)
    opts = opts or {}
    local cfg, VT = ctx.config, ctx.VT
    local bounds   = cache.bounds or { x = 0, y = 0, w = cache.w, h = cache.h }
    local bw,  bh  = VT.w, VT.h
    local x,   y   = TextAlign.xy(cfg.text_align, bw, bh, bounds.w, bounds.h)
    local ofs      = cfg.text_offset or { x = 0, y = 0 }

    x, y = x + (ofs.x or 0) + (opts.x or 0), y + (ofs.y or 0) + (opts.y or 0)
    return { x = x, y = y, w = bounds.w, h = bounds.h }
end

---____________________________
--- main: actor_point_to_local
---______________________________________
function Layout.actor_point_to_local(actor, point)
    local VT      = actor.VT;             if not VT or not point then return end
    local t, args = love.math.newTransform(), actor.args or {}
    local p0      = args.collides_with_point_point or {}

    args.collides_with_point_point        = p0
    args.collides_with_point_translation  = args.collides_with_point_translation or {}
    args.collides_with_point_rotation     = args.collides_with_point_rotation    or {}
    p0.x, p0.y = point.x, point.y

    if actor.container and actor.container ~= actor and actor._to_container then actor:_to_container(p0) end

    local ds, p   = actor, actor.layered_parallax or { x = 0, y = 0 }
    local sx, sy  = (VT.scale or 1)*(ds.draw_scale_x or 1), (VT.scale or 1)*(ds.draw_scale_y or 1)
    if sx == 0 or sy == 0 then return end

    local ax,  ay   = ds.draw_anchor_x or 0.5, ds.draw_anchor_y or 0.5
    local dx,  dy   = ds.draw_offset_x or 0,   ds.draw_offset_y or 0
    local shx, shy  = ds.draw_shear_x or 0,    ds.draw_shear_y or 0

    t:translate(VT.x + VT.w*ax + (p.x or 0) + dx, VT.y + VT.h*ay + (p.y or 0) + dy)
    if VT.r ~= 0 or actor.jitter then t:rotate(VT.r) end
    if shx ~= 0 or shy ~= 0 then t:shear(shx, shy) end
    t:translate(-VT.w*sx*ax, -VT.h*sy*ay)
    t:scale(sx, sy)

    local x, y = t:inverseTransformPoint(p0.x, p0.y)
    return { x = x, y = y }
end

function Layout.point_in_rotated_box(point, box, r)
    local cx, cy  = box.x + 0.5*box.w, box.y + 0.5*box.h
    local dx, dy  = point.x - cx, point.y - cy
    if r and r ~= 0 then local cr, sr = cos(-r), sin(-r); dx, dy = dx*cr - dy*sr, dx*sr + dy*cr end

    return dx >= -0.5*box.w and dy >= -0.5*box.h and dx <= 0.5*box.w and dy <= 0.5*box.h
end

---____________________________
--- main: text_bg_cfg
---______________________________________
function Layout.text_bg_cfg(ctx)
    local cfg = ctx.config or {}
    local bg  = cfg.text_bg
    if bg == N then return end
    if bg == Y or bg == nil then return {} end
    return bg
end

---____________________________
--- main: text_bg_box
---______________________________________
function Layout.text_bg_box(ctx, cache, text_box)
    local bg      = Layout.text_bg_cfg(ctx);              if not bg then return end
    local cfg, b  = ctx.config or {}, cache.bounds or { x = 0, y = 0, w = cache.w, h = cache.h }

    local ox,   oy     = _first_non_nil(bg.x, bg.ox, 0), _first_non_nil(bg.y, bg.oy, 0)
    local bscale       = bg.scale
    local sx,   sy     = bg.scale_x or bg.sx or (type(bscale) == "table" and bscale.x) or (type(bscale) == "number" and bscale),
                         bg.scale_y or bg.sy or (type(bscale) == "table" and bscale.y) or (type(bscale) == "number" and bscale)
    local s_bw, s_bh   = sx or 0.4, sy or 0.1
    local bw,   bh     = s_bw*b.w, s_bh*b.h
    local bx,   by     = text_box.x + 0.5*(1 - s_bw)*b.w + ox, text_box.y + 0.5*(1 - s_bh)*b.h + oy
    local br,   color  = _first_non_nil(bg.r, cfg.text_bg_r,  cache.r or 0), bg.color or cfg.text_bg_color or { 0, 0, 0, 0.28 }

    return { x = bx, y = by, w = bw, h = bh, r = br, color = color }
end

return Layout
