local LG = love.graphics

local min, max = math.min, math.max
local Y = true

return function (CardFront)
--------------------------------------------------
--- Helpers: debug field coordinates
--------------------------------------------------
local function _debug_field_coord_text(self)
    local card = self.role and self.role.draw_major
    local gm, cell = card and card.gm, card and card.cell
    local zone = card and card.zone
    local debug_gamepad = gm and gm.CTRL and gm.CTRL.debug_gamepad_mode
    if not (gm and ((gm.debug and gm.debug.on) or debug_gamepad) and cell and cell.row and cell.col) then return end
    if not (zone and zone.config and zone.config.type == "field") then return end
    local p = zone.field_view_cell_debug_points and zone:field_view_cell_debug_points(cell.row, cell.col)
    local T = card.T or {}
    local cx, cy = (T.x or 0) + 0.5*(T.w or 0), (T.y or 0) + 0.5*(T.h or 0)
    if not p then return ("(%s, %s)\nT %.2f, %.2f\nC %.2f, %.2f"):format(tostring(cell.row), tostring(cell.col), T.x or 0, T.y or 0, cx, cy) end
    return ("(%s, %s)\nT %.2f, %.2f\nQ %.2f, %.2f\nF %.2f, %.2f"):format(tostring(cell.row), tostring(cell.col), T.x or 0, T.y or 0, p.quad.x or 0, p.quad.y or 0, p.world.x or 0, p.world.y or 0)
end

function CardFront:refresh_debug_field_coords()
    local text = _debug_field_coord_text(self)
    if self.debug_field_coord_text == text then return end
    self.debug_field_coord_text, self.face_dirty = text, Y
end

function CardFront:draw_debug_field_coords(cw, ch)
    local text = self.debug_field_coord_text
    if not text then return end

    local font = LG.getFont()
    local text_w, lines = 0, 1
    for line in tostring(text):gmatch("[^\n]+") do text_w = max(text_w, font:getWidth(line)) end
    for _ in tostring(text):gmatch("\n") do lines = lines + 1 end
    local scale = min((cw*0.76)/max(text_w, 1), (ch*0.30)/max(font:getHeight()*lines, 1))
    local tw, th = text_w*scale, font:getHeight()*lines*scale
    local x, y = 0.5*(cw - tw), 0.5*(ch - th)

    LG.setColor(0, 0, 0, 0.72); LG.print(text, x + 2, y + 2, 0, scale, scale)
    LG.setColor(1, 1, 1, 0.95); LG.print(text, x, y, 0, scale, scale)
end

end
