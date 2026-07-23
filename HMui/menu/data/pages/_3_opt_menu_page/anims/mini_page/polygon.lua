local Common   = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.common")
local Settings = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.settings")

local START, ENTER, EXIT = Settings.START, Settings.ENTER, Settings.EXIT

local M = {}

-----------------------------
--- color helpers
-----------------------------
local function _own_color(tab)
    if type(tab) ~= "table" then return end
    local owned = {}
    for k, v in pairs(tab) do owned[k] = v end
    return owned
end
local function _target_alpha(color) return type(color) == "table" and (color[4] == nil and 1 or color[4]) or 1 end

-----------------------------
--- point helpers
-----------------------------
local function _fade_start(polygon)    return Common.mini_at(polygon.fade_start or START[polygon.fade_start_key or "root"] or START.root) end
local function _fade_duration(polygon) return polygon.fade_duration or polygon.fade_time or ENTER.curtain_duration end
local function _point_xy(point)        return point.x or point[1] or 0, point.y or point[2] or 0 end
local function _set_point_xy(point, x, y) if point.x ~= nil or point.y ~= nil then point.x, point.y = x, y else point[1], point[2] = x, y end end

local function _point_enter_from(polygon, point, i)
    local from = point.enter_from or polygon.enter_from_points or polygon.enter_from;     if not from then return end
    if from[1] and type(from[1]) == "table" then from = from[i] end
    if not from then return end
    return from.x or from[1] or 0, from.y or from[2] or 0
end

local function _point_enter_xy(polygon, point, i)
    local enter = point.enter_point or polygon.enter_points;     if not enter then return end
    if enter[1] and type(enter[1]) == "table" then enter = enter[i] end
    if not enter then return end
    return enter.x or enter[1] or 0, enter.y or enter[2] or 0
end

local function _point_cut_xy(polygon, i)
    local cut = polygon.cut_points or polygon.intermediate_points;     if not cut then return end
    if cut[1] and type(cut[1]) == "table" then cut = cut[i] end
    if not cut then return end
    return cut.x or cut[1] or 0, cut.y or cut[2] or 0
end

local function _enter_duration(polygon) return polygon.enter_duration or polygon.enter_time or _fade_duration(polygon) end

-----------------------------
--- enter points
-----------------------------
local function _offset_points(polygon)
    for i, point in ipairs(polygon.points or polygon) do
        if type(point) == "table" then
            local x, y = _point_xy(point)
            point.enter_home_x, point.enter_home_y = x, y
            local sx, sy = _point_enter_xy(polygon, point, i)
            if sx then _set_point_xy(point, sx, sy); goto continue end
            local ox, oy = _point_enter_from(polygon, point, i)
            if ox then _set_point_xy(point, x + ox, y + oy) end
        end
        ::continue::
    end
end

local function _ease_points_home(gm, polygon)
    for i, point in ipairs(polygon.points or polygon) do
        if type(point) == "table" then
            local hx, hy = point.enter_home_x, point.enter_home_y
            local tx, ty = _point_cut_xy(polygon, i)
            if not tx then tx, ty = hx, hy end
            if tx == nil then local ox, oy = _point_enter_from(polygon, point, i); if ox then local x, y = _point_xy(point); tx, ty = x - ox, y - oy end end
            if tx == nil then goto continue end
            Common.ease(gm, point, point.x ~= nil and "x" or 1, tx, _enter_duration(polygon), "sine")
            Common.ease(gm, point, point.y ~= nil and "y" or 2, ty, _enter_duration(polygon), "sine")
        end
        ::continue::
    end
end

local function _snap_points_home(polygon)
    if not (polygon.cut_points or polygon.intermediate_points) then return end
    for _, point in ipairs(polygon.points or polygon) do
        if type(point) == "table" then
            local hx, hy = point.enter_home_x, point.enter_home_y
            if hx == nil then goto continue end
            _set_point_xy(point, hx, hy)
        end
        ::continue::
    end
end

-----------------------------
--- fade_curtain
-----------------------------
function M.fade_curtain(gm, root)
    local polygons = root and root.config and root.config.page_region_polygons;     if not polygons then return end
    for _, polygon in ipairs(polygons) do
        local color = _own_color(polygon.color);    if not color then goto continue end
        local alpha = _target_alpha(color)
        polygon.color = color
        color[4] = 0
        _offset_points(polygon)
        Common.after(gm, _fade_start(polygon), function() _ease_points_home(gm, polygon); Common.after(gm, _enter_duration(polygon), function() _snap_points_home(polygon); return true end); return Common.ease(gm, color, 4, alpha, _fade_duration(polygon), "sine") end)
        ::continue::
    end
end

-----------------------------
--- pull_curtain
-----------------------------
function M.pull_curtain(gm, root)
    local polygons = root and root.config and root.config.page_region_polygons;     if not polygons then return end
    for _, polygon in ipairs(polygons) do
        for _, point in ipairs(polygon.points or polygon) do
            if type(point) == "table" then Common.ease_exit(gm, point, "y", (point.y or point[2] or 0) + EXIT.curtain_pull_y, EXIT.pull_duration, "sine") end
        end
    end
end

return M
