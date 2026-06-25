local U = require("HMEng.entities.board.gridzone.focus_projection.utils")

local abs, max = math.abs, math.max
local Y, N = true, false

return function (GridZone)
-----------------------------
--- config / state
----------------------------
function GridZone:_focus_projection_cfg()
    local cfg = self.config or {}
    local Fcfg = self.gm and self.gm.Fcfg or {}
    return cfg.focus_projection or Fcfg.focus_projection
end

function GridZone:_focus_projection_cell()
    local anchor = self.field_view_anchor_cell
    if anchor and anchor.row and anchor.col then return anchor end
    local ctrl = self.gm and self.gm.CTRL
    local fcell = ctrl and (ctrl.navigate_field or ctrl.gamepad_focus_scope == "field") and ctrl.field_focus_cell
    if fcell and fcell.row and fcell.col then return fcell end
    local pawn = self.gm and self.gm.field_pawn
    local cell = pawn and pawn.zone == self and pawn.cell
    if cell and cell.row and cell.col then return cell end
end

function GridZone:focus_projection_weight()
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return 0 end
    if not self.focus_projection_active then return 0 end
    local cam = self.gm and self.gm.camera
    local cell = self:_focus_projection_cell();      if not (cam and cam.active and cell) then return 0 end
    local z0, z1 = cfg.zoom_start or 1.05, cfg.zoom_end or 1.6
    local zoom = (cfg.track_zoom_settle == Y and cam.zoom) or cam.target_zoom or cam.zoom or 1
    return U.clamp01((zoom - z0)/max(z1 - z0, 1e-6))*(cfg.max_weight or 1)
end

function GridZone:_focus_projection_state()
    local cell = self:_focus_projection_cell()
    local w = self:focus_projection_weight()
    local key = cell and (tostring(cell.row) .. ":" .. tostring(cell.col)) or "none"
    return key, w
end

function GridZone:focus_projection_state_dirty()
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return N end
    if not (self.focus_projection_active or self.focus_projection_pending) then return N end
    local key, w = self:_focus_projection_state()
    return key ~= self.focus_projection_key or abs(w - (self.focus_projection_weight_last or 0)) > (cfg.weight_snap or 0.004)
end

function GridZone:refresh_focus_projection_state()
    if not self:focus_projection_state_dirty() then return N end
    self.focus_projection_key, self.focus_projection_weight_last = self:_focus_projection_state()
    return Y
end

function GridZone:mark_focus_projection_dirty()
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return end
    self.focus_projection_active, self.focus_projection_pending = Y, Y
    self:mark_card_layout_dirty()
    self:mark_pawn_layout_dirty()
end

end
