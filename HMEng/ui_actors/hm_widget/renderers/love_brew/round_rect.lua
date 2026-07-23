local Render = require("HMfns.systems.render")
local C      = require("HMfns.animate.color.color_const")
local LG     = love.graphics

local push_draw_trans = Render.push_actor_draw_transform

local Y = true

local M = {}

M.config_keys = {
    "fill_color", "hover_color", "hover_tint", "parent_hover_tint", "shadow", "shadow_color", "round_radius",
    "hit_shape", "hit_padding", "hit_scale", "hit_offset",
}

--- Helper: color_with_alpha
local function color_with_alpha(color, alpha)
    color = color or C.BLACK
    return { color[1], color[2], color[3], (color[4] or 1)*(alpha or 1) }
end

--- Helper: draw_round_rect
local function draw_round_rect(x, y, w, h, radius, color)
    LG.setColor(color)
    LG.rectangle("fill", x, y, w, h, radius, radius)
end

---____________________________
--- main: init
---______________________________________
function M.init(self) self.draw_alpha = self.draw_alpha or 1 end

---____________________________
--- main: hit_test
---______________________________________
function M.hit_test() return Y end

---____________________________
--- main: draw
---______________________________________
function M.draw(self)
    local VT, tz = self.VT, self.rcfg.tile_size
    local radius = self.config.round_radius or 0.04
    local color = self:resolve_visual_color("fill_color") or self.config.fill_color or C.BLACK
    local alpha = self.draw_alpha or 1

    push_draw_trans(self)
    if self.config.shadow == Y then
        local sp = self.shadow_parallax or { x = 0, y = 0 }
        draw_round_rect(-0.5*sp.x/tz, -0.5*sp.y/tz, VT.w, VT.h, radius, color_with_alpha(self.config.shadow_color or C.BLACK, alpha))
    end
    draw_round_rect(0, 0, VT.w, VT.h, radius, color_with_alpha(color, alpha))
    LG.pop()
end

return M
