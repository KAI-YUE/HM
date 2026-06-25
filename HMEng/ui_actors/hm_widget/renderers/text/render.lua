local Render       = require("HMfns.systems.render")
local renderers    = require("HMEng.ui_actors.hm_widget.renderers")
local TextAlign    = require("HMEng.ui_actors.hm_widget.renderers.text.text_align")
local TextDraw     = require("HMEng.ui_actors.hm_widget.renderers.text.draw")
local TextMask     = require("HMEng.ui_actors.hm_widget.renderers.text.mask")
local TextMetrics  = require("HMEng.ui_actors.hm_widget.renderers.text.metrics")
local LG           = love.graphics

local push_draw_trans = Render.push_actor_draw_transform

local Y, N = true, false

--- Helper: _text_layout_box_from_T
local function _text_layout_box_from_T(self, T) local VT = self.VT; return { x = T.x or 0, y = T.y or 0, w = T.w or VT.w, h = T.h or VT.h } end



return function(HMWidget)
-----------------------------
--- draw text overlay
----------------------------------
---- Helper: text_layout_box
function HMWidget:text_layout_box()
    local cfg       = self.config;                       if cfg.text_box_T then return _text_layout_box_from_T(self, cfg.text_box_T) end
    local renderer  = renderers[cfg.renderer];           if renderer and renderer.text_layout_box then return renderer.text_layout_box(self) end
    local VT        = self.VT;                           return { x = 0, y = 0, w = VT.w, h = VT.h }
end

---_________________________________
--- main: draw_text_overlays
---_________________________________
function HMWidget:draw_text_overlay()
    local cfg = self.config;                              if cfg.text_overlay == N then return end
    if not cfg.text and not (cfg.ref_table and cfg.ref_value) then return end
    self:update_text()

    local drawable, lang = cfg.text_drawable, cfg.lang;   if not (drawable or cfg.text_drawable_runs) or not lang then return end

    local box, tz, font  = self:text_layout_box(), self.rcfg.tile_size, lang.font
    local pad,    scale  = cfg.text_padding or { x = 0.2, y = 0.1 }, (cfg.text_scale or cfg.scale or 0.5) * font.font_scale / tz
    local bw,     bh     = box.w - 2*(pad.x or 0), box.h - 2*(pad.y or 0)
    cfg._text_render_tz  = tz
    local tw,     th     = TextMetrics.text(cfg, font, scale)
    local ftw,    fth    = TextMetrics.fit(cfg, font, scale)
    local fit,    maxw   = nil, cfg.text_maxw or bw
    fit, scale, tw, th, ftw, fth = TextMetrics.fit_scale(cfg, maxw, tw, th, ftw, fth, scale)
    cfg._text_render_fit = fit

    local align_w, align_h = cfg.text_reveal == Y and ftw or tw, cfg.text_reveal == Y and fth or th
    local x,       y       = TextAlign.xy(cfg.text_align, bw, bh, align_w, align_h)
    local ofs              = cfg.text_offset or { x = 0, y = 0 }
    x, y = box.x + x + (pad.x or 0) + (ofs.x or 0), box.y + y + (pad.y or 0) + (ofs.y or 0)

    local color = TextDraw.color(self, cfg)
    local pressed, p_dist = self:button_press_distance()
    if cfg.no_press_squash then pressed, p_dist = N, 0 end
    local sp = self.shadow_parallax or { x = 0, y = 0 }
    local px, py = pressed and -sp.x*p_dist/tz or 0, pressed and -sp.y*p_dist/tz or 0

    local tight_mask_box = { x = x + px, y = y + py, w = tw, h = th }
    local mask_box = TextMask.box(self, box, tight_mask_box)

    if cfg.text_shadow == Y and cfg.shadow and self.SET.s_graphics.shadows == "On" then
        push_draw_trans(self, 0.97)
        local shadow_mask_box = TextMask.box(self, box, { x = x + px - 0.5*sp.x/tz, y = y + py - 0.5*sp.y/tz, w = tw, h = th })
        local shader_on, old_shader = TextMask.apply(self, shadow_mask_box)
        TextDraw.text(cfg, drawable, x + px - 0.5*sp.x/tz, y + py - 0.5*sp.y/tz, { 0, 0, 0, 0.3*(color[4] or 1) }, scale)
        if shader_on then LG.setShader(old_shader) end
        LG.pop()
    end

    push_draw_trans(self)
    local shader_on, old_shader = TextMask.apply(self, mask_box)
    TextDraw.text(cfg, drawable, x + px, y + py, color, scale)
    if shader_on then LG.setShader(old_shader) end
    LG.pop()
    
    cfg._text_render_tz, cfg._text_render_fit = nil, nil
end

end
