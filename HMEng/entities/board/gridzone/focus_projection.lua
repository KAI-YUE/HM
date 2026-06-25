local abs, floor, max, min = math.abs, math.floor, math.max, math.min

local Y, N = true, false

return function (GridZone)
------------------------------------------------------
--- Focus projection helpers
------------------------------------------------------
--- Helpers: clamp01 | lerp
local function _clamp01(v) return max(0, min(1, v or 0)) end
local function _lerp(a, b, t) return a + (b - a)*t end

--- Helper: quad center
local function _quad_center(quad)
    local x, y = 0, 0
    for i = 1, 4 do x, y = x + quad[i].x, y + quad[i].y end
    return { x = 0.25*x, y = 0.25*y }
end

--- Helper: quad ops
local function _translate_quad(quad, dx, dy)
    return { { x = quad[1].x + dx, y = quad[1].y + dy }, { x = quad[2].x + dx, y = quad[2].y + dy }, { x = quad[3].x + dx, y = quad[3].y + dy }, { x = quad[4].x + dx, y = quad[4].y + dy } }
end

local function _lerp_quad(a, b, t)
    return { { x = _lerp(a[1].x, b[1].x, t), y = _lerp(a[1].y, b[1].y, t) }, { x = _lerp(a[2].x, b[2].x, t), y = _lerp(a[2].y, b[2].y, t) }, { x = _lerp(a[3].x, b[3].x, t), y = _lerp(a[3].y, b[3].y, t) }, { x = _lerp(a[4].x, b[4].x, t), y = _lerp(a[4].y, b[4].y, t) } }
end

local function _local_quad(quad, T)
    local ox, oy = (T and T.x) or 0, (T and T.y) or 0
    return { { x = quad[1].x - ox, y = quad[1].y - oy }, { x = quad[2].x - ox, y = quad[2].y - oy }, { x = quad[3].x - ox, y = quad[3].y - oy }, { x = quad[4].x - ox, y = quad[4].y - oy } }
end

local function _world_quad(quad, T)
    local ox, oy = (T and T.x) or 0, (T and T.y) or 0
    return { { x = quad[1].x + ox, y = quad[1].y + oy }, { x = quad[2].x + ox, y = quad[2].y + oy }, { x = quad[3].x + ox, y = quad[3].y + oy }, { x = quad[4].x + ox, y = quad[4].y + oy } }
end

local function _quad_delta(a, b)
    local d = 0
    for i = 1, 4 do d = max(d, abs(a[i].x - b[i].x), abs(a[i].y - b[i].y)) end
    return d
end

------------------------------------------------------
--- focus projection cfg/state
------------------------------------------------------
--- Helper: focus projection cfg
function GridZone:_focus_projection_cfg()
    local cfg = self.config or {}
    local Fcfg = self.gm and self.gm.Fcfg or {}
    return cfg.focus_projection or Fcfg.focus_projection
end

--- Helper: focus projection cell
function GridZone:_focus_projection_cell()
    local ctrl = self.gm and self.gm.CTRL
    local fcell = ctrl and (ctrl.navigate_field or ctrl.gamepad_focus_scope == "field") and ctrl.field_focus_cell
    if fcell and fcell.row and fcell.col then return fcell end
    local pawn = self.gm and self.gm.field_pawn
    local cell = pawn and pawn.zone == self and pawn.cell
    if cell and cell.row and cell.col then return cell end
end

--- Helper: focus projection weight
function GridZone:focus_projection_weight()
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return 0 end
    if not self.focus_projection_active then return 0 end
    local cam = self.gm and self.gm.camera
    local cell = self:_focus_projection_cell();      if not (cam and cam.active and cell) then return 0 end
    local z0, z1 = cfg.zoom_start or 1.05, cfg.zoom_end or 1.6
    return _clamp01(((cam.zoom or 1) - z0)/max(z1 - z0, 1e-6))*(cfg.max_weight or 1)
end

--- Helper: focus projection state
function GridZone:_focus_projection_state()
    local cell = self:_focus_projection_cell()
    local w = self:focus_projection_weight()
    local key = cell and (tostring(cell.row) .. ":" .. tostring(cell.col)) or "none"
    return key, w
end

--- Helper: focus projection state dirty
function GridZone:focus_projection_state_dirty()
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return N end
    if not (self.focus_projection_active or self.focus_projection_pending) then return N end
    local key, w = self:_focus_projection_state()
    return key ~= self.focus_projection_key or abs(w - (self.focus_projection_weight_last or 0)) > (cfg.weight_snap or 0.004)
end

--- Helper: refresh focus projection state
function GridZone:refresh_focus_projection_state()
    if not self:focus_projection_state_dirty() then return N end
    self.focus_projection_key, self.focus_projection_weight_last = self:_focus_projection_state()
    return Y
end

--- Helper: mark focus projection dirty
function GridZone:mark_focus_projection_dirty()
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return end
    self.focus_projection_active, self.focus_projection_pending = Y, Y
    self:mark_card_layout_dirty()
end

--- Helper: queue focus projection after pawn lands
function GridZone:queue_focus_projection_after_land(pawn)
    local cfg = self:_focus_projection_cfg();        if not cfg or cfg.enabled == N then return end
    if pawn ~= (self.gm and self.gm.field_pawn) then return end
    local td = pawn.toddle
    if td and td.active then pawn.focus_projection_after_land = Y; return end
    self:mark_focus_projection_dirty()
end

------------------------------------------------------
--- focus quad build
------------------------------------------------------
--- Helper: centered proxy cell
function GridZone:_focus_proxy_cell(r_idx, c_idx, focus)
    local cfg = self:_focus_projection_cfg() or {}
    local cr = cfg.center_row or floor(0.5*(self.n_rows or 1) + 0.5)
    local cc = cfg.center_col or floor(0.5*(self.n_cols or 1) + 0.5)
    return cr + r_idx - focus.row, cc + c_idx - focus.col, cr, cc
end

--- Helper: focus proxy quad
function GridZone:_focus_proxy_quad(r_idx, c_idx, focus)
    local projector = self.projector;               if not projector then return end
    local pr, pc, cr, cc = self:_focus_proxy_cell(r_idx, c_idx, focus)
    if pr < 1 or pc < 1 or pr > self.n_rows or pc > self.n_cols then return end

    local proxy_quad  = projector:get_cell_quad(pr, pc)
    local base_focus  = projector:get_cell_quad(focus.row, focus.col)
    local proxy_focus = projector:get_cell_quad(cr, cc)
    if not (proxy_quad and base_focus and proxy_focus) then return end

    local a, b = _quad_center(base_focus), _quad_center(proxy_focus)
    return _translate_quad(proxy_quad, a.x - b.x, a.y - b.y)
end

--- Helper: focus projected quad
function GridZone:get_focus_projected_quad(r_idx, c_idx)
    local projector = self.projector;               if not projector then return end
    local base = projector:get_cell_quad(r_idx, c_idx)
    local weight = self:focus_projection_weight()
    if not base or weight <= 0 then return base end

    local focus = self:_focus_projection_cell();    if not focus then return base end
    local proxy = self:_focus_proxy_quad(r_idx, c_idx, focus)
    if not proxy then return base end
    return _lerp_quad(base, proxy, weight)
end

--- Helper: smooth projected quad
function GridZone:_smooth_projected_quad(card, target, dt)
    local cfg = self:_focus_projection_cfg() or {}
    local mesh_card = card.children and card.children.mesh_card
    local current = mesh_card and mesh_card.projected_quad
    if cfg.smoothing == N or cfg.smoothing == 0 then return target end
    if not (current and dt and dt > 0) then return target end

    local a = min(1, (cfg.smoothing or 12)*dt)
    local current_world = _world_quad(current, mesh_card.T)
    local target_world  = _world_quad(target, card.T)
    local out = _local_quad(_lerp_quad(current_world, target_world, a), card.T)
    if _quad_delta(out, target) <= (cfg.snap or 0.002) then return target end
    self.focus_projection_pending = Y
    return out
end

--- Helper: projected quad for card
function GridZone:projected_quad_for_card(r_idx, c_idx, card, args)
    local quad = self:get_focus_projected_quad(r_idx, c_idx);        if not quad then return end
    local target = _local_quad(quad, card.T)
    return self:_smooth_projected_quad(card, target, args and args.dt)
end

end
