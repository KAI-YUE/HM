local U = require("HMEng.entities.board.gridzone.focus_projection.utils")

local Y, N = true, false

return function (GridZone)
-----------------------------
--- field view anchor
----------------------------
function GridZone:field_view_cell_debug_points(r_idx, c_idx)
    local row = self.cells and self.cells[r_idx]
    local card = row and row[c_idx]
    if not card then return end
    local T = card.T or {}
    local raw = { x = T.x or 0, y = T.y or 0 }
    local center = { x = raw.x + 0.5*(T.w or 0), y = raw.y + 0.5*(T.h or 0) }
    local quad = self:get_projected_quad_at(r_idx, c_idx)
    local visual = quad and U.quad_center(quad) or center
    local lp = U.actor_parallax(card)
    local local_point = { x = visual.x + (lp.x or 0), y = visual.y + (lp.y or 0) }
    local cam = self.gm and self.gm.camera
    local wx, wy = local_point.x, local_point.y
    if cam and cam.resolve_object_point then wx, wy = cam:resolve_object_point(self, local_point.x, local_point.y) end
    return { raw = raw, center = center, quad = visual, local_point = local_point, world = { x = wx, y = wy } }
end

function GridZone:field_view_cell_point(r_idx, c_idx)
    local p = self:field_view_cell_debug_points(r_idx, c_idx);      if not p then return end
    return { x = p.world.x, y = p.world.y, raw = p.raw, center = p.center, quad = p.quad, local_point = p.local_point }
end

function GridZone:set_field_view_anchor(r_idx, c_idx)
    local point = self:field_view_cell_point(r_idx, c_idx);        if not point then return end
    self.field_view_anchor_cell = { row = r_idx, col = c_idx }
    local cam = self.gm and self.gm.camera
    if cam and cam.set_focus_point then cam:set_focus_point(point.x, point.y) end
    return point
end

function GridZone:commit_field_view_projection(args)
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return N end
    args = args or {}
    self.focus_projection_active, self.focus_projection_pending = Y, Y
    if self.refresh_focus_projection_state then self:refresh_focus_projection_state() end
    local dt = args.snap and 0 or (args.dt or cfg.commit_dt or 1/60)
    if self.align_cards then self:align_cards({ dt = dt }) end
    local cell = self.field_view_anchor_cell
    if cell and cell.row and cell.col then self:set_field_view_anchor(cell.row, cell.col) end
    return Y
end

function GridZone:field_view_cell_screen_point(r_idx, c_idx)
    local point, cam = self:field_view_cell_point(r_idx, c_idx), self.gm and self.gm.camera
    if not (point and cam) then return end
    self._field_view_screen_point = self._field_view_screen_point or {}
    return cam:world_to_screen_point(point, self._field_view_screen_point)
end

function GridZone:field_view_dest_offscreen(r_idx, c_idx)
    local cfg, cam = self:_focus_projection_cfg() or {}, self.gm and self.gm.camera
    local p = self:field_view_cell_screen_point(r_idx, c_idx);      if not (p and cam) then return N end
    local vp, mx, my = cam.viewport, (cfg.safe_margin_u or 0.22)*(cam.viewport.w or 0), (cfg.safe_margin_v or cfg.safe_margin_u or 0.22)*(cam.viewport.h or 0)
    return p.x < vp.x + mx or p.x > vp.x + vp.w - mx or p.y < vp.y + my or p.y > vp.y + vp.h - my
end

function GridZone:prepare_field_view_move(pawn, r_idx, c_idx)
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N or cfg.camera_anchor == N then return N end
    if pawn ~= (self.gm and self.gm.field_pawn) then return N end
    if not self.field_view_anchor_cell then local cell = pawn.cell or {}; self:set_field_view_anchor(cell.row or r_idx, cell.col or c_idx) end
    if not self:field_view_dest_offscreen(r_idx, c_idx) then return N end
    if not self:set_field_view_anchor(r_idx, c_idx) then return N end
    return self:commit_field_view_projection()
end

end
