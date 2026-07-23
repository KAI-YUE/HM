local Paint  = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect.paint")
local TextFx = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect.textfx")
local Render = require("HMfns.systems.render")
local C      = require("HMfns.animate.color.color_const")
local LG     = love.graphics

local push_draw_trans = Render.push_actor_draw_transform

local N = false

local M = {}

-----------------------------
--- paint cfg helpers
-----------------------------
--- Helper: reusable paint draw config
local function _paint_draw_cfg(self)
    local out = self.paint_rect_draw_cfg or {}
    self.paint_rect_draw_cfg = out
    for k in pairs(out) do out[k] = nil end
    return out
end

--- Helper: paint cfg
local function _paint_cfg(self)
    local cfg  = self.config
    local src  = cfg.paint or cfg
    local out  = _paint_draw_cfg(self)
    for k, v in pairs(src) do
        if k ~= "_paint_bleed_src" and k ~= "_paint_bleed_layer_cfg" then out[k] = v end
    end

    out.color        = self:resolve_visual_color("fill_color") or out.color or cfg.color or C.BLACK
    out.shadow       = cfg.shadow
    out.shadow_color = cfg.shadow_color or out.shadow_color
    return out
end

---____________________________
--- main: draw
---____________________________
function M.draw(self)
    local VT,      tz      = self.VT, self.rcfg.tile_size
    local wpx,     hpx     = VT.w * tz, VT.h * tz
    local pressed, p_dist  = self:button_press_distance()
    local sp               = self.shadow_parallax or { x = 0, y = 0 }
    local dx, dy           = pressed and -sp.x*p_dist or 0, pressed and -sp.y*p_dist or 0

    if self.config.paint_bg ~= N then
        push_draw_trans(self, pressed and 0.985 or 1)
        LG.scale(1 / tz)
        Paint.draw_bleed_layer(self, { x = dx, y = dy, w = wpx, h = hpx }, _paint_cfg(self), N)
        LG.pop()
    end

    TextFx.draw(self, dx, dy)
end

return M
