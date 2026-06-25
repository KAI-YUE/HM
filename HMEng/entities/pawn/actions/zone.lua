local Y, N = true, false

return function (Pawn)
-------------------------------------------------------
--- can move to cell
-------------------------------------------------------
function Pawn:can_move_to_cell(r_idx, c_idx)
    local zone = self.zone
    if not zone or not zone.pawns then return N end
    if r_idx < 1 or c_idx < 1 or r_idx > zone.n_rows or c_idx > zone.n_cols then return N end

    local cells = zone.cells
    local cell_row = cells and cells[r_idx]
    if not cell_row or not cell_row[c_idx] then return N end

    return Y
end

-------------------------------------------------------
--- set zone
-------------------------------------------------------
function Pawn:set_zone(zone)
    self.zone = zone
    self.parent = zone
    self.layered_parallax = zone and zone.layered_parallax 
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(self) end
end

-------------------------------------------------------
--- set cell | clear cell | place on cell
-------------------------------------------------------
function Pawn:set_cell(r_idx, c_idx) self.cell.row, self.cell.col = r_idx, c_idx end
function Pawn:clear_cell()           self:set_cell(nil, nil) end
function Pawn:place_on_cell(zone, r_idx, c_idx) if zone then self:set_zone(zone) end; self:set_cell(r_idx, c_idx) end

-------------------------------------------------------
--- move to cell
-------------------------------------------------------
function Pawn:move_to_cell(r_idx, c_idx)
    local zone = self.zone
    if not zone or not self:can_move_to_cell(r_idx, c_idx) then return N end

    local cell = self.cell or {}
    if cell.row == r_idx and cell.col == c_idx then return Y end

    local prev_row, prev_col = cell.row, cell.col
    local view_anchor_changed = zone.prepare_field_view_move and zone:prepare_field_view_move(self, r_idx, c_idx)
    zone:remove_pawn(self)

    if zone:emplace_pawn(self, r_idx, c_idx) then self:begin_toddle(); if view_anchor_changed and zone.queue_focus_projection_after_land then zone:queue_focus_projection_after_land(self) end; return Y end
    if prev_row and prev_col then zone:emplace_pawn(self, prev_row, prev_col) end
    return N
end

end
