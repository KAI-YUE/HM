local BoardReveal = require("HMGplay.board.reveal")

local Y = true

local M = {}

--------------------------------------------------
--- Helpers: hovered field cell
--------------------------------------------------
local function _point_in_quad(point, quad)
    local sign
    for i = 1, 4 do
        local a, b = quad[i], quad[(i % 4) + 1]
        local cross = (point.x - a.x)*(b.y - a.y) - (point.y - a.y)*(b.x - a.x)
        if math.abs(cross) > 1e-6 then
            local current = cross > 0
            if sign ~= nil and sign ~= current then return false end
            sign = current
        end
    end
    return true
end

local function _cell_from_target(ctrl)
    local target = ctrl.hovering and ctrl.hovering.target
    local cell   = target and target.cell
    if cell and cell.row and cell.col then return cell.row, cell.col end

    local gm, point = ctrl.gm or G, ctrl.cursor_hover and ctrl.cursor_hover.T
    local zone = gm and gm.gridzone
    if not zone or not point then return end
    if gm.camera and gm.camera.active then
        ctrl._debug_field_point = ctrl._debug_field_point or {}
        point = gm.camera:screen_to_world_point(point, ctrl._debug_field_point)
    end
    for row = 1, zone.n_rows do
        for col = 1, zone.n_cols do
            local metrics = zone:get_cell_metrics(row, col)
            if metrics and metrics.quad and _point_in_quad(point, metrics.quad) then return row, col end
        end
    end
end

--------------------------------------------------
--- Main: spawn debug field card
--------------------------------------------------
function M.handle(ctrl, key)
    if key ~= "r" then return end
    local gm = ctrl.gm or G
    if not (gm and gm.run_loop and gm.gridzone and gm.field) then return end

    local row, col = _cell_from_target(ctrl);           if not row then return end
    ctrl.debug_field_r_handled = Y
    BoardReveal.reveal_hidden_cell(gm, row, col)
    return Y
end

return M
