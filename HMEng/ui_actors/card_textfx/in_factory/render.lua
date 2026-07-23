local Render       = require("HMfns.systems.render")
local Background   = require("HMEng.ui_actors.card_textfx.in_factory.paint.background")
local HoverIdle    = require("HMEng.ui_actors.card_textfx.in_factory.hover_idle")
local Hint         = require("HMEng.ui_actors.card_textfx.in_factory.paint.hint")
local IconCross    = require("HMEng.visual.hover_fx.icon_cross")
local Layout       = require("HMEng.ui_actors.card_textfx.in_factory.layout")
local ShaderUtils  = require("HMEng.visual.shader_utils")
local LG           = love.graphics

local abs, cos, max, min, pi = math.abs, math.cos, math.max, math.min, math.pi
local push_draw_trans   = Render.push_actor_draw_transform
local enqueue_drawable  = Render.enqueue_drawable
local send_uniform      = ShaderUtils.send_sp_uniform

local Y, N = true, false

return function (CardTextFx)
-----------------------------
--- draw cache
----------------------------------
--- Helper: clamp
local function _clamp(v, lo, hi) return min(hi, max(lo, v)) end
local function _draw_alpha(ctx)
    local cfg = ctx.config or {}
    return _clamp((cfg.textfx_alpha == nil and 1 or cfg.textfx_alpha) * (cfg.slot_enter_alpha == nil and 1 or cfg.slot_enter_alpha) * (ctx.draw_alpha or 1), 0, 1)
end

--- Helper: _hover_icon_cfg
local function _hover_icon_cfg(ctx)
    local cfg = ctx.config or {}
    if not (cfg.opt_tab_hovered and cfg.hover_icons) then return end
    local icons = cfg.hover_icons
    if type(icons) ~= "table" then return end
    return icons
end

--- Helper: _draw_hover_icons
local function _draw_hover_icons(ctx, box)
    local icons = _hover_icon_cfg(ctx);               if not icons then return end
    IconCross.draw(ctx.gm, ctx, box, icons, ctx.config and ctx.config.tab_hover_started_at, _draw_alpha(ctx))
end

--- Helper: _draw_pendulum_string
local function _draw_pendulum_string(ctx, box)
    local string = ctx.config and ctx.config.pendulum_string
    local alpha = string and (string.alpha or 0) or 0
    if alpha <= 0.001 then return end

    local color = string.color or { 1, 1, 1, 1 }
    local pivot = string.pivot or { x = 0, y = -3 }
    local ax, ay = string.attach_x or 0.5, string.attach_y or 0.5
    local x2, y2 = box.x + box.w*ax, box.y + box.h*ay
    local old_width = LG.getLineWidth()

    LG.setLineWidth(string.width or 0.012)
    LG.setColor(color[1], color[2], color[3], (color[4] or 1)*alpha*_draw_alpha(ctx))
    LG.line(x2 + (pivot.x or 0) - (ctx.draw_offset_x or 0), y2 + (pivot.y or -3) - (ctx.draw_offset_y or 0), x2, y2)
    LG.setLineWidth(old_width)
end

--- Helper: textfx mask shader
local function _apply_fx_mask(ctx, box)
    local fx_mask = ctx.fx_mask or 0
    local light_sweep = ctx.light_sweep or 0
    if fx_mask <= 0.001 and light_sweep <= 0.001 then return end
    local cfg      = ctx.config or {}
    local shader   = ctx.gm.t_shaders and ctx.gm.t_shaders[cfg.fx_mask_shader or "_-2_stroke_wipe"];      if not shader then return end

    local x0, y0 = LG.transformPoint(box.x,         box.y)
    local x1, y1 = LG.transformPoint(box.x + box.w, box.y)
    local x2, y2 = LG.transformPoint(box.x,         box.y + box.h)
    local x3, y3 = LG.transformPoint(box.x + box.w, box.y + box.h)

    local sx0, sy0 = min(x0, x1, x2, x3), min(y0, y1, y2, y3)
    local sx1, sy1 = max(x0, x1, x2, x3), max(y0, y1, y2, y3)
    local sw,  sh  = max(sx1 - sx0, 1), max(sy1 - sy0, 1)
    local now      = ctx.gm._T.real_s or 0
    local old      = LG.getShader()

    ShaderUtils.send_base_uniforms(shader, {
        fx_mask       = _clamp(fx_mask, 0, 1),
        time          = now,
        tex_details   = { 0, 0, sw, sh },
        image_details = { sw, sh },
        shadow        = N,
    })
    send_uniform(shader, "fx_mask_dir", ctx.fx_mask_dir or 1)
    send_uniform(shader, "light_sweep", light_sweep)
    send_uniform(shader, "light_sweep_brightness", ctx.light_sweep_brightness or 0)
    send_uniform(shader, "wipe_rect", { sx0, sy0, sw, sh })
    send_uniform(shader, "generic",   { 0, now, ctx.ID or 0 })
    LG.setShader(shader)
    return Y, old
end

--- Helper: draw letter
function CardTextFx:_draw_letter(letter, x, y, flip, shadow)
    local pw,    ph    = letter.paper_w, letter.paper_h
    local c,     pad   = cos(pi * flip), letter.paper_pad
    local squeeze      = abs(c)
    local sx,    dir   = max(0.05, squeeze), c < 0 and -1 or 1
    local text_alpha   = min(1, max(0, (squeeze - 0.14) / 0.22))
    local px,    py    = x + letter.x + letter.ox, y + letter.y + letter.oy

    LG.push()
    LG.translate(px + 0.5*pw, py + 0.5*ph)
    LG.rotate(letter.r)
    LG.scale(sx, 1)
    LG.translate(-0.5*pw, -0.5*ph)

    Background.draw_letter_bg(self, letter, shadow, { x = px, scale_x = sx })
    if shadow == "only" then return LG.pop() end
    if text_alpha <= 0 then return LG.pop() end

    local tc = letter.text_color
    LG.setColor(tc[1], tc[2], tc[3], (tc[4] or 1)*text_alpha*_draw_alpha(self))
    LG.push()
    LG.translate(0.5*pw, 0.5*ph)
    LG.scale(dir, 1)
    LG.translate(-0.5*pw, -0.5*ph)
    LG.draw(letter.text, pad.x, pad.y, 0, letter.draw_sx, letter.draw_sy)
    LG.pop()

    LG.pop()
end

---____________________________
--- main: draw_cache
---______________________________________
function CardTextFx:draw_cache(text, opts)
    opts = opts or {}
    local cache = self:build(text);       if not cache then return end

    local now = self.gm._T.real_s

    local box, bounds  = Layout.text_visual_box(self, cache, opts), cache.bounds or { x = 0, y = 0, w = cache.w, h = cache.h }
    local x,   y       = box.x - bounds.x, box.y - bounds.y

    push_draw_trans(self, nil, self.draw_rotate or 0)
    if not opts.shadow_only then _draw_pendulum_string(self, box) end
    Background.draw_text_bg(self, cache, x, y, { shadow_only = opts.shadow_only, skip_shadow = opts.skip_shadow })

    local shader_on, old_shader
    if not opts.shadow_only then shader_on, old_shader = _apply_fx_mask(self, box) end
    if not opts.shadow_only then Hint.draw_hover_hint(self, cache, x, y, opts.text_hint_fx_mask) end

    HoverIdle.update(self, cache, now)

    for _, letter in ipairs(cache.letters) do
        local flip = HoverIdle.progress(self, cache, letter, now)
        self:_draw_letter(letter, x, y, _clamp(flip, 0, 1), opts.shadow)
    end

    if not opts.shadow_only then _draw_hover_icons(self, box) end
    if shader_on then LG.setShader(old_shader) end
    LG.pop()
end

---____________________________
--- main: draw
---______________________________________
function CardTextFx:draw(opts)
    local opts,   cfg       = opts or {}, self.config
    local shadow, text      = (cfg.text_shadow ~= N) and cfg.shadow and (self.SET.s_graphics.shadows == "On"), tostring(self.config.text or "")
    local fx_mask           = opts.text_hint_fx_mask

    if opts.shadow_only then shadow = shadow and "only" or N end
    if opts.skip_shadow then shadow = N end

    self:draw_cache(text, { shadow = shadow, shadow_only = opts.shadow_only, skip_shadow = opts.skip_shadow, text_hint_fx_mask = fx_mask })
    if opts.shadow_only then return end
    self:sync_runtime_child_alignment()
    self:draw_children()

    if self.states.collide.can then enqueue_drawable(self.t_drawable, self) end
    self:bound_me()
end

end
