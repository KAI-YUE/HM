local M = {}

--- Helper: _stroke_shadow_offset
local function _stroke_shadow_offset(self, sdx, sdy)
    local cfg       = self.config
    local sp        = cfg.shadow_parallax or self.shadow_parallax or {}
    local dist, tz  = cfg.widget_dist or 2.55, self.rcfg.tile_size
    local ox,   oy  = cfg.stroke_shadow_x or (cfg.stroke_shadow_offset and cfg.stroke_shadow_offset.x), cfg.stroke_shadow_y or (cfg.stroke_shadow_offset and cfg.stroke_shadow_offset.y)
    return ox or (sdx - (sp.x or 0)*dist/tz), oy or (sdy - (sp.y or 0.1)*dist/tz)
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self, wpx, hpx, dx, dy, sdx, sdy)
    local sprites = self.page_stroke_sprites;       if not sprites then return end

    local cfg    = self.config
    local color  = self:resolve_visual_color("stroke_color") or cfg.tint
    local sx, sy = _stroke_shadow_offset(self, sdx or 0, sdy or 0)

    for _, sprite in ipairs(sprites) do sprite:draw({ wpx = wpx, hpx = hpx, dx = dx, dy = dy, color = color, shadow = cfg.shadow, shadow_color = cfg.shadow_color, shadow_x = sx, shadow_y = sy }) end
end

return M
