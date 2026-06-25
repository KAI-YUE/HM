local Class       = require("core.class")
local Data        = require("HMEng.visual.stroked_brush.data.strokes")
local ShaderUtils = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local LTP           = LG.transformPoint
local _send_uniform = ShaderUtils.send_sp_uniform

local min, max = math.min, math.max

local Y, N = true, false

local StrokeBrush = Class:extend()

------------------------------------
--- init
------------------------------------
--- Helper: sprite metrics
local function _sprite_metrics(quad) local _, _, w, h = quad:getViewport(); return { w = w, h = h } end

--- Helper: copy stroke cfg
local function _merge_stroke_cfg(args)
    local key = args.stroke_key or args.key or args.quad_key
    local base, cfg = Data[key] or {}, {}
    for k, v in pairs(base) do cfg[k] = v end
    for k, v in pairs(args) do cfg[k] = v end
    cfg.key = key
    cfg.quad_key = cfg.quad_key or key
    return cfg
end

---______________________________________
--- main: init
---______________________________________
function StrokeBrush:init(gm, args, default_atlas_key)
    local cfg = _merge_stroke_cfg(args or {});    if not cfg.quad_key then return end
    self.gm, self.config = gm, cfg
    

    local atlas_key = cfg.atlas_key or default_atlas_key or "ui_pack"
    local atlas = gm.T_atlas[atlas_key];          if not atlas then return end
    local quad  = atlas:get_quad(cfg.quad_key)

    self.atlas, self.img, self.quad = atlas, atlas.image, quad
    self.metrics = _sprite_metrics(quad)
end

------------------------------------
--- draw
------------------------------------
--- Helper: rotated screen bounds
local function _rotated_screen_bounds(x, y, w, h, r, ax, ay)
    LG.push()
    LG.translate(x + ax*w, y + ay*h)
    if r ~= 0 then LG.rotate(r) end

    local x0, y0  = LTP(-ax*w,     -ay*h)
    local x1, y1  = LTP((1-ax)*w,  -ay*h)
    local x2, y2  = LTP(-ax*w,     (1-ay)*h)
    local x3, y3  = LTP((1-ax)*w,  (1-ay)*h)
    LG.pop()

    return min(x0, x1, x2, x3), min(y0, y1, y2, y3), max(x0, x1, x2, x3), max(y0, y1, y2, y3)
end


--- Helper: apply fx mask shader
local function _apply_fx_mask(gm, args, x, y, w, h, r, ax, ay, shadow)
    local fx_mask     = args.fx_mask;                      if fx_mask == nil then return end
    local shader_name = args.fx_mask_shader or "_-1_page_wipe"
    local shader      = gm.t_shaders[shader_name];         if not shader then return nil, nil, Y end

    local old_shader          = LG.getShader()
    local sx0, sy0, sx1, sy1  = _rotated_screen_bounds(x, y, w, h, r, ax, ay)
    local sw, sh              = max(sx1 - sx0, 1), max(sy1 - sy0, 1)
    local time, tex_details   =  args.time or gm._T.real_s, { 0, 0, sw, sh }
    
    ShaderUtils.send_base_uniforms(shader, { fx_mask = fx_mask,  time = time,     tex_details   = tex_details,
        image_details = { sw, sh },          shadow  = shadow,     c1  = args.c1,   c2           = args.c2 })

    _send_uniform(shader, "fx_mask_dir", args.fx_mask_dir or 0)
    _send_uniform(shader, "fx_mask_seed", args.fx_mask_seed or 0)
    _send_uniform(shader, "wipe_rect", { sx0, sy0, sw, sh })
    _send_uniform(shader, "generic",   { 0, time, args.id or 0 })
    LG.setShader(shader)
    return Y, old_shader
end

--- Helper: draw pass
local function _draw_pass(self, geom, args, pass)
    pass = pass or {}
    local shader_on, old_shader, missing_shader = _apply_fx_mask(args.gm or self.gm, args, geom.x + pass.ox, geom.y + pass.oy, geom.w, geom.h, geom.r, geom.ax, geom.ay, pass.shadow)
    if missing_shader and args.hide_without_fx_mask_shader then return N, missing_shader end

    if pass.color then LG.setColor(pass.color) end
    LG.draw(self.img, self.quad, geom.x + pass.ox + geom.ax*geom.w, geom.y + pass.oy + geom.ay*geom.h, geom.r, geom.sx, geom.sy, geom.ax*geom.metrics.w, geom.ay*geom.metrics.h)
    if shader_on then LG.setShader(old_shader) end
    return Y
end

--- Helper: resolve sprite box
local function _resolve_box(stroke, wpx, hpx, metrics)
    local ox, oy   = stroke.ox or 0, stroke.oy or 0
    local oy_base  = (stroke.oy_base == "w" and wpx) or hpx
    local x,  y    = (stroke.x or 0) * wpx + ox*wpx, (stroke.y or 0) * hpx + oy*oy_base
    local w,  h    = stroke.w and stroke.w*wpx, stroke.h and stroke.h*hpx

    if not w and not h then local scale = stroke.scale or 1; w, h = metrics.w*scale, metrics.h*scale
    elseif not w       then w = h * metrics.w / metrics.h
    elseif not h       then h = w * metrics.h / metrics.w end

    local ax, ay = stroke.ax or 0, stroke.ay or 0
    return x - ax*w, y - ay*h, w, h
end

---___________________________________
--- main: draw 
---___________________________________
function StrokeBrush:draw(args)
    if not self.quad then return end
    args = args or {}

    local stroke, metrics  = self.config, self.metrics
    local x, y,   w, h     = _resolve_box(stroke, args.wpx or 0, args.hpx or 0, metrics)
    local sx,     sy       = w / metrics.w, h / metrics.h
    local r                = (args.r or stroke.r or 0) - (stroke.base_r or 0)
    local ax,     ay       = stroke.rot_ax or stroke.draw_ax or 0, stroke.rot_ay or stroke.draw_ay or 0
    local geom             = { x = x + (args.dx or 0), y = y + (args.dy or 0), w = w, h = h, sx = sx, sy = sy, r = r, ax = ax, ay = ay, metrics = metrics }

    if args.shadow and args.shadow_color then
        local drawn, missing = _draw_pass(self, geom, args, {
            ox      = args.shadow_x or args.shadow_ox or 0,
            oy      = args.shadow_y or args.shadow_oy or 0,
            color   = args.shadow_color,
            shadow  = Y,
        })
        if missing and args.hide_without_fx_mask_shader then return end
    end

    _draw_pass(self, geom, args, { ox = 0, oy = 0, color = args.color })
end

return StrokeBrush
