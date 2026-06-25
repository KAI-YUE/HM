local Actor = require("HMEng.actors.actor")

return function (Pawn)
-------------------------------------------------------
--- calculate parallax
-------------------------------------------------------
function Pawn:calculate_parallax()
    Actor.calculate_parallax(self)

    local sp = self.shadow_parallax;            if not sp then return end

    local zone, cell = self.zone, self.cell or {}
    local row        = zone and zone.cells and cell.row and zone.cells[cell.row]
    if not row then return end

    local p,      depth   = self.params or {}, row.row_depth or 0
    local near_y, far_y   = p.shadow_y_near or -1.8, p.shadow_y_far  or -0.6

    sp.y = (near_y + (far_y - near_y)*depth)
end

end
