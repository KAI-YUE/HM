local Actor = require("HMEng.actors.actor")

local min, max = math.min, math.max

local Y, N = true, false

return function (FieldCard)
-------------------------------------------------------
--- calculate parallax
-------------------------------------------------------
function FieldCard:calculate_parallax()
	local _room = self._room;  if not _room then return end
    
    local gm, T,  sp      = self.gm, self.T, self.shadow_parallax
    local RT, Tw, Tx      = _room.T, T.w, T.x
    local gparallax       = gm.parallax or {}
    local pivot_x, halfW  = gparallax.pivot_x, RT.w/2
    local raw,     bound  = ((0.3*pivot_x + Tx + Tw*0.5))/halfW, 0.07*pivot_x
    sp.x = max(-2*bound, min(bound, raw))

    local zone, cell = self.zone, self.cell or {}
    local row = zone and zone.cells and cell.row and zone.cells[cell.row]
    if not row then return end

    local p,      depth  = self.params or {},       row.row_depth or 0
    local near_y, far_y  = p.shadow_y_near or -0.8, p.shadow_y_far or -0.6

    sp.y = (near_y + (far_y - near_y)*depth)
end


end
