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
    return "(" .. tostring(cell.row) .. ", " .. tostring(cell.col) .. ")"
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
    local scale = min((cw*0.42)/max(font:getWidth(text), 1), (ch*0.11)/max(font:getHeight(), 1))
    local tw, th = font:getWidth(text)*scale, font:getHeight()*scale
    local x, y = 0.5*(cw - tw), 0.5*(ch - th)

    LG.setColor(0, 0, 0, 0.72); LG.print(text, x + 2, y + 2, 0, scale, scale)
    LG.setColor(1, 1, 1, 0.95); LG.print(text, x, y, 0, scale, scale)
end

end
