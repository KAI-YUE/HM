local ApplyShader = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.apply_shader")

local LG = love.graphics

local M = {}

-----------------------------
--- regions
----------------------------------
--- Helper: draw_seamed_region
local function _draw_seamed_region(self, region, wpx, hpx, dx, dy, r, w, h)
    local oy_base = (region.oy_base == "w" and wpx) or hpx

    local px,        py          = (region.px or 0)*wpx + (region.ox or 0)*wpx + dx, (region.py or 0)*hpx + (region.oy or 0)*oy_base + dy
    local shader_on, old_shader  = ApplyShader.apply_seam_shader(self, region, px, py, r, wpx, hpx)

    LG.push();                        LG.translate(px, py)
    if r ~= 0 then LG.rotate(r) end;  LG.rectangle("fill", (region.x or 0) * wpx, (region.y or 0) * hpx, w, h)
    LG.pop();                         ApplyShader.clear_shader(shader_on, old_shader)
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self, wpx, hpx, dx, dy)
    local cfg      = self.config
    local regions  = cfg.page_regions;          if not regions then return end
    local alpha    = (cfg.page_region_alpha == nil and 1) or cfg.page_region_alpha

    for i, region in ipairs(regions) do
        local color = cfg.page_colors[i]
        if not color or (color[4] or 1) < 0.01 then goto continue end
        color = { color[1], color[2], color[3], (color[4] or 1)*alpha }

        local x, y  = (region.x or 0)*wpx + dx, (region.y or 0)*hpx + dy
        local w, h  = (region.w or 1)*wpx,      (region.h or 1)*hpx
        local r     = region.r or 0

        LG.setColor(color)
        if region.px or region.py then _draw_seamed_region(self, region, wpx, hpx, dx, dy, r, w, h); goto continue; end
        if r == 0 then LG.rectangle("fill", x, y, w, h); goto continue end

        LG.push();          LG.translate(x + 0.5 * w, y + 0.5 * h)
        LG.rotate(r);       LG.rectangle("fill", -0.5 * w, -0.5 * h, w, h)
        LG.pop()

        ::continue::
    end
end

return M
