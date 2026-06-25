local Actor = require("HMEng.actors.actor")
local C = require("HMfns.animate.color.color_const")

local LG = love.graphics

local Y, N = true, false

return function(RoutePreview)
-----------------------------
--- helpers: color | path
-----------------------------
local function _set_color(color, alpha) LG.setColor(color[1], color[2], color[3], (color[4] or 1)*(alpha or 1)) end

local function _draw_path(self, cells, color, alpha, close_loop)
    if not cells or #cells == 0 then return end
    local points = {}
    for _, cell in ipairs(cells) do
        local x, y = self:_cell_point(cell)
        points[#points + 1] = x
        points[#points + 1] = y
    end
    if close_loop and #cells > 2 then
        local x, y = self:_cell_point(cells[1])
        points[#points + 1] = x
        points[#points + 1] = y
    end
    _set_color(color, alpha)
    if #points >= 4 then LG.line(points) end
end

-----------------------------
--- draw
-----------------------------
function RoutePreview:draw()
    if not (self.states.visible and self.board) then return end

    local T = self.T
    local norm = self.rcfg.tile_scale * self.rcfg.tile_size
    LG.push()
    LG.scale(norm)
    LG.translate(T.x, T.y)

    _set_color(C.UI.WIDGET_DARK, 0.82)
    LG.rectangle("fill", 0, 0, T.w, T.h, 0.18, 0.18)

    LG.setLineWidth(0.035)
    for _, path in ipairs(self.board.paths or {}) do _draw_path(self, path.cells, C.UI.INACTIVE, 0.42, Y) end
    for _, bridge in ipairs(self.board.bridges or {}) do _draw_path(self, bridge.cells, C.GREEN, 0.9, N) end

    local bridge_source = self.board.bridge_interaction and self.board.bridge_interaction.source
    if bridge_source then
        local x, y = self:_cell_point(bridge_source)
        _set_color(C.GREEN, 1)
        LG.circle("line", x, y, 0.14)
    end

    LG.setLineWidth(0.09)
    _draw_path(self, self.route, C.ORANGE, 1, N)
    for i, cell in ipairs(self.route) do
        local x, y = self:_cell_point(cell)
        _set_color(i == #self.route and C.RED or C.ORANGE, 1)
        LG.circle("fill", x, y, i == #self.route and 0.11 or 0.065)
    end

    local pip_count = math.min(self.steps, 10)
    for i = 1, pip_count do
        _set_color(C.ORANGE, 0.95)
        LG.rectangle("fill", 0.28 + (i - 1)*0.25, T.h - 0.27, 0.16, 0.08, 0.04, 0.04)
    end

    LG.setColor(1, 1, 1, 1)
    LG.pop()
    Actor.draw(self)
end

end
