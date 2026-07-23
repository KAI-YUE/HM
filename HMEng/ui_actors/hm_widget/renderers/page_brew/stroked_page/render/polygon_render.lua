local ApplyShader = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.apply_shader")

local LG, LM = love.graphics, love.math

local M = {}

-----------------------------
--- polygon
----------------------------------
--- Helper: polygon_color
local function _polygon_color(self, polygon, alpha)
    local cfg    = self.config
    local color  = polygon.color or (polygon.color_i and cfg.page_colors and cfg.page_colors[polygon.color_i])
    if not color or (color[4] or 1) < 0.01 then return end
    return { color[1], color[2], color[3], (color[4] or 1)*alpha }
end

--- Helper: polygon_point
local function _polygon_point(self, polygon, point, wpx, hpx, dx, dy)
    local x, y = point.x or point[1] or 0, point.y or point[2] or 0
    if polygon.coord == "room" or polygon.room_ref then
        local VT, tz = self.VT, self.rcfg.tile_size
        return (x - VT.x)*tz + dx, (y - VT.y)*tz + dy
    end
    return x*wpx + dx, y*hpx + dy
end

--- Helper: polygon_points
local function _polygon_points(self, polygon, wpx, hpx, dx, dy)
    local rect         = polygon.rect
    local points, out  = polygon.points or polygon, {}
    if rect then
        local x, y, w, h = rect.x or rect[1] or 0, rect.y or rect[2] or 0, rect.w or rect[3] or 0, rect.h or rect[4] or 0
        points = {
            { x = x,     y = y     }, { x = x + w, y = y     },
            { x = x + w, y = y + h }, { x = x,     y = y + h },
        }
    end
    for i, point in ipairs(points) do
        if type(point) == "table" then
            local x, y = _polygon_point(self, polygon, point, wpx, hpx, dx, dy)
            out[#out + 1] = x
            out[#out + 1] = y
            goto continue
        elseif  i % 2 ~= 1  then goto continue end

        if polygon.coord == "room" or polygon.room_ref then
            local VT, tz = self.VT, self.rcfg.tile_size
            out[#out + 1] = (point - VT.x)*tz + dx
            out[#out + 1] = ((points[i + 1] or 0) - VT.y)*tz + dy
        else
            out[#out + 1] = point*wpx + dx
            out[#out + 1] = (points[i + 1] or 0)*hpx + dy
        end
        ::continue::
    end
    return out
end

--- Helper: _is_convex | _draw_polygon_fill
local function _is_convex(points) local ok, convex = pcall(LM.isConvex, points); return ok and convex end
local function _draw_polygon_fill(points)
    if _is_convex(points) then return LG.polygon("fill", points) end
    local ok, triangles = pcall(LM.triangulate, points); if not ok then return LG.polygon("fill", points) end
    for _, triangle in ipairs(triangles) do LG.polygon("fill", triangle) end
end

function M.draw(self, wpx, hpx, dx, dy)
    local cfg      = self.config
    local polygons = cfg.page_region_polygons;                                      if not polygons then return end
    local alpha    = (cfg.page_region_alpha == nil and 1) or cfg.page_region_alpha

    for _, polygon in ipairs(polygons) do
        local color  = _polygon_color(self, polygon, alpha);                        if not color then goto continue end
        local points = _polygon_points(self, polygon, wpx, hpx, dx, dy);            if #points < 6 then goto continue end

        LG.setColor(color)
        local shader_on, old_shader = ApplyShader.apply_polygon_shader(self, polygon, points, wpx, hpx)
        _draw_polygon_fill(points)
        ApplyShader.clear_shader(shader_on, old_shader)

        ::continue::
    end
end

return M
