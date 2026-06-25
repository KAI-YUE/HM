local C  = require("HMfns.animate.color.color_const")
local LG = love.graphics

local M = {}

--- Helper: _text_squish
local function _text_squish(cfg, font) return cfg.text_squish or font.squish or 1 end

---____________________________
--- main: alpha
---____________________________
function M.alpha(self, cfg)
    local a = cfg.text_alpha
    if a == nil then a = cfg.paint_alpha end
    if a == nil then a = cfg.textfx_alpha end
    if a == nil then a = 1 end
    if cfg.description_hover_key or cfg.hover_description_alpha ~= nil then a = a * (cfg.hover_description_alpha or 1) end
    a = a * (self.draw_alpha or 1)
    if a < 0 then return 0 elseif a > 1 then return 1 end
    return a
end

---____________________________
--- main: color
---____________________________
function M.color(self, cfg)
    local color = self:resolve_visual_color("text_color") or cfg.color or C.UI.TEXT_LIGHT or C.WHITE
    return { color[1], color[2], color[3], (color[4] or 1)*M.alpha(self, cfg) }
end

---____________________________
--- main: text
---____________________________
function M.text(cfg, drawable, x, y, color, scale)
    local runs = cfg.text_drawable_runs
    if not runs then
        local font = cfg.lang.font
        local TO = font.font_offset or { x = 0, y = 0 }
        LG.setColor(color)
        LG.draw(drawable, x + TO.x*scale, y + TO.y*scale, 0, _text_squish(cfg, font)*scale, scale)
        return
    end

    local dx = 0
    for _, run in ipairs(runs) do
        local font    = run.font_cfg
        local rscale  = (cfg.text_scale or cfg.scale or 0.5)*font.font_scale/cfg._text_render_tz*(cfg._text_render_fit or 1)
        local TO      = font.font_offset or { x = 0, y = 0 }
        local rule    = type(run.rule) == "table" and run.rule or {}
        local oy      = (rule.y_offset or 0)*(cfg._text_render_fit or 1)

        LG.setColor(color)
        LG.draw(run.drawable, x + dx + TO.x*rscale, y + oy + TO.y*rscale, 0, _text_squish(cfg, font)*rscale, rscale)
        dx = dx + run.drawable:getWidth() * _text_squish(cfg, font) * rscale
    end
end

return M
