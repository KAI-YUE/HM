local U = require("HMEng.entities.board.gridzone.focus_projection.utils")

local floor, max, min = math.floor, math.max, math.min
local Y, N = true, false

return function (GridZone)
-----------------------------
--- focus quad build
----------------------------
function GridZone:_focus_proxy_cell(r_idx, c_idx, focus)
    local cfg = self:_focus_projection_cfg() or {}
    local cr = cfg.center_row or floor(0.5*(self.n_rows or 1) + 0.5)
    local cc = cfg.center_col or floor(0.5*(self.n_cols or 1) + 0.5)
    return cr + r_idx - focus.row, cc + c_idx - focus.col, cr, cc
end

function GridZone:_focus_proxy_quad(r_idx, c_idx, focus)
    local projector = self.projector;               if not projector then return end
    local pr, pc, cr, cc = self:_focus_proxy_cell(r_idx, c_idx, focus)
    if pr < 1 or pc < 1 or pr > self.n_rows or pc > self.n_cols then return end

    local proxy_quad  = projector:get_cell_quad(pr, pc)
    local base_focus  = projector:get_cell_quad(focus.row, focus.col)
    local proxy_focus = projector:get_cell_quad(cr, cc)
    if not (proxy_quad and base_focus and proxy_focus) then return end

    local a, b = U.quad_center(base_focus), U.quad_center(proxy_focus)
    return U.translate_quad(proxy_quad, a.x - b.x, a.y - b.y)
end

function GridZone:get_focus_projected_quad(r_idx, c_idx)
    local projector = self.projector;               if not projector then return end
    local base = projector:get_cell_quad(r_idx, c_idx)
    local weight = self:focus_projection_weight()
    if not base or weight <= 0 then return base end

    local focus = self:_focus_projection_cell();    if not focus then return base end
    local proxy = self:_focus_proxy_quad(r_idx, c_idx, focus)
    if not proxy then return base end
    return U.lerp_quad(base, proxy, weight)
end

local function _inside_smooth_radius(self, args, cfg)
    local radius = cfg.smooth_radius;                          if not radius then return Y end
    local focus = self:_focus_projection_cell();               if not (focus and args and args.r_idx and args.c_idx) then return Y end
    return max(math.abs(args.r_idx - focus.row), math.abs(args.c_idx - focus.col)) <= radius
end

function GridZone:_smooth_projected_quad(card, target, args)
    local cfg = self:_focus_projection_cfg() or {}
    local mesh_card = card.children and card.children.mesh_card
    local current = mesh_card and mesh_card.projected_quad
    if cfg.smoothing == N or cfg.smoothing == 0 then return target end
    if not _inside_smooth_radius(self, args, cfg) then return target end
    local dt = args and args.dt
    if not (current and dt and dt > 0) then return target end

    local a = min(1, (cfg.smoothing or 12)*dt)
    local current_world = U.world_quad(current, mesh_card.T)
    local target_world  = U.world_quad(target, card.T)
    local out = U.local_quad(U.lerp_quad(current_world, target_world, a), card.T)
    if U.quad_delta(out, target) <= (cfg.snap or 0.002) then return target end
    self.focus_projection_pending = Y
    return out
end

function GridZone:take_focus_projection_pending_cells()
    local pending = self.focus_projection_pending_cells;       if not pending then self.focus_projection_pending = N; return {} end
    local out = {}
    for _, cell in pairs(pending) do out[#out + 1] = cell end
    self.focus_projection_pending_cells, self.focus_projection_pending = nil, N
    return out
end

function GridZone:projected_quad_for_card(r_idx, c_idx, card, args)
    local quad = self:get_focus_projected_quad(r_idx, c_idx);        if not quad then return end
    local target = U.local_quad(quad, card.T)
    local out = self:_smooth_projected_quad(card, target, args)
    if out ~= target and args and args.r_idx and args.c_idx then
        local key = tostring(args.r_idx) .. ":" .. tostring(args.c_idx)
        self.focus_projection_pending_cells = self.focus_projection_pending_cells or {}
        self.focus_projection_pending_cells[key] = { row = args.r_idx, col = args.c_idx }
    end
    return out
end

end
