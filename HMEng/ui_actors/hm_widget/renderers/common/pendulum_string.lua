local LG = love.graphics

local M = {}

--- main: visible
function M.visible(widget)
    local string = widget and widget.config and widget.config.pendulum_string
    return string and (string.alpha or 0) > 0.001
end

--- Helper: _push_string_transform
local function _push_string_transform(widget, scale, offset)
    LG.push()

    local rcfg = widget.rcfg
    LG.scale(rcfg.tile_scale*rcfg.tile_size)

    local VT, ds = widget.VT, widget
    local o      = offset or { x = 0, y = 0 }
    local p      = widget.layered_parallax or (widget.parent and widget.parent.layered_parallax) or { x = 0, y = 0 }
    local x, y   = VT.x, VT.y
    local w, h   = VT.w, VT.h
    local s      = scale or 1
    local vs     = VT.scale
    local sx     = vs*s*(ds.draw_scale_x or 1)
    local sy     = vs*s*(ds.draw_scale_y or 1)
    local dx     = ds.draw_offset_x or 0
    local dy     = ds.draw_offset_y or 0
    local ax     = ds.draw_anchor_x or 0.5
    local ay     = ds.draw_anchor_y or 0.5
    local shx    = ds.draw_shear_x or 0
    local shy    = ds.draw_shear_y or 0

    LG.translate(x + w*ax + o.x + p.x + dx, y + h*ay + o.y + p.y + dy)
    if shx ~= 0 or shy ~= 0 then LG.shear(shx, shy) end

    LG.translate(-w*sx*ax, -h*sy*ay)
    LG.scale(sx, sy)
    LG.scale(1 / rcfg.tile_size)
end

--- Helper: _draw_line
local function _draw_line(widget, wpx, hpx)
    local string = widget.config.pendulum_string
    local alpha  = string and string.alpha or 0
    if alpha <= 0.001 then return end

    local tz, pivot = widget.rcfg.tile_size, string.pivot or { x = 0, y = -3 }
    local ax, ay    = string.attach_x or 0.5, string.attach_y or 0.13
    local x2, y2    = ax*wpx, ay*hpx
    local x1        = x2 + ((pivot.x or 0) - (widget.draw_offset_x or 0))*tz
    local y1        = y2 + ((pivot.y or -3) - (widget.draw_offset_y or 0))*tz
    local color     = string.color or { 1, 1, 1, 1 }
    local old_width = LG.getLineWidth()

    LG.setLineWidth((string.width or 0.012)*tz)
    LG.setColor(color[1], color[2], color[3], (color[4] or 1)*alpha*(widget.draw_alpha or 1))
    LG.line(x1, y1, x2, y2)
    LG.setLineWidth(old_width)
end

--- main: draw
function M.draw(widget, wpx, hpx, scale, offset)
    if not M.visible(widget) then return end
    _push_string_transform(widget, scale, offset)
    _draw_line(widget, wpx, hpx)
    LG.pop()
end

return M
