local Render = require("HMfns.systems.render")
local LG     = love.graphics

local push_draw_trans = Render.push_actor_draw_transform

local M = {}

M.config_keys = {
    "atlas_key", "strokes", "stroke_color", "fill_color",
    "fill_padding", "hit_shape", "hit_padding",
    "hover_color", "hover_tint", "click_visual_time", "widget_dist",
    "shadow", "shadow_color", "shadow_parallax", "sprite_color", "stroke_shadow_order", "no_press_squash",
}

-----------------------------
--- init
----------------------------------
local function _sprite_metrics(quad) local _, _, w, h = quad:getViewport(); return { w = w, h = h } end
function M.init(self, gm)
    local cfg = self.config
    local atlas = gm.T_atlas[cfg.atlas_key]
    if not atlas then return end

    self.stroke_atlas, self.stroke_img = atlas, atlas.image
    self.stroke_sprites = {}

    for _, stroke in ipairs(cfg.strokes or {}) do
        local key = stroke.quad_key
        if not key then goto continue end
        local quad = atlas:get_quad(key)
        self.stroke_sprites[#self.stroke_sprites + 1] = { config = stroke, quad = quad, metrics = _sprite_metrics(quad) }
        ::continue::
    end
end

---____________________________
--- main: hit_test
---______________________________________
function M.hit_test() return true end

-----------------------------
--- draw
----------------------------------
--- Helper: resolve box
local function _resolve_box(stroke, wpx, hpx, metrics)
    local x, y  = (stroke.x or 0) * wpx,    (stroke.y or 0) * hpx
    local w, h  = stroke.w and stroke.w*wpx, stroke.h and stroke.h*hpx

    if not w and not h then local scale = stroke.scale or 1; w, h = metrics.w * scale, metrics.h * scale
    elseif not w       then w = h * metrics.w / metrics.h
    elseif not h       then h = w * metrics.h / metrics.w end

    local ax, ay = stroke.ax or 0, stroke.ay or 0
    return x - ax*w, y - ay*h, w, h
end

--- Helper: draw fill
local function _draw_fill(self, wpx, hpx, dx, dy, shadow)
    local cfg = self.config
    local fill = self:resolve_visual_color("fill_color"); if not fill or (fill[4] or 1) <= 0.01 then return end
    local color = shadow and cfg.shadow_color or fill;    if not color or (color[4] or 1) <= 0.01 then return end

    local pad = cfg.fill_padding or 0
    LG.setColor(color)
    LG.rectangle("fill", pad*wpx + dx, pad*hpx + dy, (1 - 2*pad)*wpx, (1 - 2*pad)*hpx)
end

--- Helper: stroke color
local function _stroke_color(self, shadow)
    local cfg = self.config
    if shadow then return cfg.shadow_color or { 0, 0, 0, 1 } end
    return self:resolve_visual_color("stroke_color") or self:resolve_visual_color("sprite_color") or cfg.tint
end

--- Helper: draw stroke layer
local function _draw_stroke_sprite(img, sprite, wpx, hpx, offset)
    local stroke, metrics = sprite.config, sprite.metrics
    local x, y, w, h = _resolve_box(stroke, wpx, hpx, metrics)
    LG.draw(img, sprite.quad, x + offset.x, y + offset.y, stroke.r or 0, w / metrics.w, h / metrics.h)
end

local function _draw_stroke_layer(self, img, sprites, wpx, hpx, offset, shadow)
    _draw_fill(self, wpx, hpx, offset.x, offset.y, shadow)

    LG.setColor(_stroke_color(self, shadow))
    for _, sprite in ipairs(sprites) do _draw_stroke_sprite(img, sprite, wpx, hpx, offset) end
end

--- Helper: draw strokes per shadow
local function _draw_strokes_per_shadow(self, img, sprites, wpx, hpx, shadow_offset, face_offset)
    _draw_fill(self, wpx, hpx, shadow_offset.x, shadow_offset.y, true)
    _draw_fill(self, wpx, hpx, face_offset.x, face_offset.y, false)
    for _, sprite in ipairs(sprites) do
        LG.setColor(_stroke_color(self, true));  _draw_stroke_sprite(img, sprite, wpx, hpx, shadow_offset)
        LG.setColor(_stroke_color(self, false)); _draw_stroke_sprite(img, sprite, wpx, hpx, face_offset)
    end
end

--- Helper: press offsets
local function _press_offsets(self, pressed, p_dist)
    local cfg     = self.config
    local sp      = cfg.shadow_parallax or self.shadow_parallax or { x = 0, y = 0 }
    local dx, dy  = -sp.x * p_dist, -sp.y * p_dist

    if pressed and not cfg.no_press_squash then return { x = dx, y = dy }, { x = dx, y = dy } end
    return { x = dx, y = dy }, { x = 0, y = 0 }
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self, opts)
    local img, sprites = self.stroke_img, self.stroke_sprites
    if not img or not sprites then return end

    local cfg,     VT, tz  = self.config, self.VT, self.rcfg.tile_size
    local wpx,     hpx     = VT.w * tz, VT.h * tz
    local pressed, p_dist  = self:button_press_distance()
    local shadow_offset, face_offset = _press_offsets(self, pressed, p_dist)
    opts = opts or {}

    push_draw_trans(self, pressed and 0.985 or 1)
    LG.scale(1 / tz)

    if cfg.stroke_shadow_order == "per_stroke" and cfg.shadow and not opts.skip_shadow and not opts.shadow_only then _draw_strokes_per_shadow(self, img, sprites, wpx, hpx, shadow_offset, face_offset); LG.pop(); return end
    if cfg.shadow and not opts.skip_shadow then _draw_stroke_layer(self, img, sprites, wpx, hpx, shadow_offset, true) end
    if not opts.shadow_only then _draw_stroke_layer(self, img, sprites, wpx, hpx, face_offset, false) end

    LG.pop()
end

return M
