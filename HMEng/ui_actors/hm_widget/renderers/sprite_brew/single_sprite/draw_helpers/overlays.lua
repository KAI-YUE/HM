local Color = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.color")

local LG = love.graphics

local M = {}

--- Helper: _overlay_box
local function _overlay_box(self, overlay)
    local T    = overlay.T or overlay
    local tz   = self.rcfg.tile_size
    local OM   = overlay.metrics
    local _,  _,   qw, qh  = overlay.quad:getViewport()

    local w_units  = T.w or overlay.w or 1
    local h_units  = T.h or overlay.h or (w_units*(OM.h or qh)/(OM.w or qw))
    return (T.x or overlay.x or 0)*tz, (T.y or overlay.y or 0)*tz, w_units*tz, h_units*tz
end

--- Helper: _draw_sprite_overlay
local function _draw_sprite_overlay(self, overlay, dx, dy, shadow)
    if shadow and not overlay.shadow then return end

    local x, y, w,  h   = _overlay_box(self, overlay)
    local _, _, qw, qh  = overlay.quad:getViewport()
    local sx,   sy      = w/qw, h/qh
    local fx,   fy      = 1, 1

    if overlay.sprite_flip_x then fx = -1 end
    if overlay.sprite_flip_y then fy = -1 end
    local color = Color.overlay_color(self, overlay, shadow)

    LG.setColor(Color.with_overlay_alpha(self, color, shadow))
    LG.draw(
        overlay.img,              overlay.quad,
        x + (dx or 0) + 0.5*w,    y + (dy or 0) + 0.5*h,
        overlay.r or 0,
        sx*fx,                    sy*fy,
        0.5*qw,                   0.5*qh
    )
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self, dx, dy, shadow) for _, overlay in ipairs(self.sprite_overlays or {}) do _draw_sprite_overlay(self, overlay, dx, dy, shadow) end end

return M
