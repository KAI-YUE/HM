local Projector = require("core.transform.projector")
local Actor     = require("HMEng.actors.actor")
local RNG       = require("HMfns.utils.math.rng_utils")

local push           = table.insert
local abs, max, min  = math.abs, math.max, math.min
local hash_string32  = RNG.hash_string32
local Y, N           = true, false

--- Helpers: noise | scaled_noise | clone quad 
local function _noise(seed)                    return 2 * hash_string32(seed) - 1 end
local function _scaled_noise(seed, amp, scale) if not amp or amp == 0 then return 0 end; return _noise(seed) * amp * (scale or 1) end
local function _clone_quad(quad)               return { { x = quad[1].x, y = quad[1].y }, { x = quad[2].x, y = quad[2].y }, { x = quad[3].x, y = quad[3].y }, { x = quad[4].x, y = quad[4].y } } end

return function (GridZone)
--------------------------------------------------
--- init_gridzone_attributes
--------------------------------------------------
--- Helper: deterministic per-cell variance, composed from row/col/cell seeds.
function GridZone:_resolve_cell_pose(gm, r_idx, c_idx)
    local cfg  = self.config or {};       local vcfg = cfg.cell_variance
    if not vcfg or vcfg.enabled == N then return { x = 0, y = 0, r = 0 } end

    local game = gm.GAME or {};           local pr   = game.pseudorandom or {}
    local seed = "grid_cell"..pr.seed

    local sx, sy    = self.cell_w or gm.card_w or 1, self.cell_h or gm.card_h or 1
    local row_key   = seed .. "|row|" ..  tostring(r_idx)
    local col_key   = seed .. "|col|" ..  tostring(c_idx)
    local cell_key  = seed .. "|cell|" .. tostring(r_idx) .. "|" .. tostring(c_idx)

    return {
        x = _scaled_noise(row_key .. "|x",  vcfg.row_x,  sx) + _scaled_noise(col_key .. "|x",  vcfg.col_x,  sx) + _scaled_noise(cell_key .. "|x", vcfg.cell_x, sx),
        y = _scaled_noise(row_key .. "|y",  vcfg.row_y,  sy) + _scaled_noise(col_key .. "|y",  vcfg.col_y,  sy) + _scaled_noise(cell_key .. "|y", vcfg.cell_y, sy),
        r = _scaled_noise(row_key .. "|r",  vcfg.row_r)      + _scaled_noise(col_key .. "|r",  vcfg.col_r)      + _scaled_noise(cell_key .. "|r", vcfg.cell_r) }
end

--- Helper: init one row/cell container with row-wise modifiers
function GridZone:_init_cell(gm, r_idx)
    local cfg,    Fcfg    = self.config or {}, gm.Fcfg or {}
    local n_rows, n_cols  = self.n_rows or 1, self.n_cols or 1
    local depth           = (n_rows - r_idx)/max(n_rows - 1, 1) -- top row farther, bottom row nearer

    local near_scale, far_scale  = cfg.field_near_scale or 1.0, cfg.field_far_scale  or 0.90
    local row_scale,  far_shear  = near_scale + (far_scale - near_scale)*depth, cfg.field_far_shear

    if not far_shear then far_shear = Fcfg.shx or 0 end
    local row_shear = far_shear * depth

    local row = { row_depth = depth, row_scale = row_scale, row_shear = row_shear, cell_pose = {}, cell_metrics = {} }
    for c = 1, n_cols do
        row[c] = nil
        row.cell_pose[c] = self:_resolve_cell_pose(gm, r_idx, c)
        row.cell_metrics[c] = nil
    end
    return row
end

--________________________________
--- Main: init gridzone attributes 
--________________________________
function GridZone:init_gridzone_attributes(gm, x, y, w, h, config)
    Actor.init(self, gm, x, y, w, h)

    self.config, self.cells   = config or {}, {}
    self.static_move          = self.config.static_move ~= N
    self:refresh_move_registry()
    if gm.refresh_render_context then gm:refresh_render_context(self) end
    self.card_layout_dirty, self.pawn_layout_dirty = N, N
    local rcfg,  cfg, T       = gm.rcfg, self.config, self.T
    local _r,    _c           = cfg.n_rows or 1, cfg.n_cols or 1
    self.n_rows, self.n_cols  = _r, _c  
    self.cell_w, self.cell_h  = cfg.card_w or gm.card_w, cfg.card_h or gm.card_h

    self.projector = Projector(T.x, T.y, T.w, T.h, { rcfg = rcfg, room = gm._room })
    self.projector:build_grid(_r, _c, T, cfg.projector)

    self.pawns = {}
    for i = 1, _r do  -- pawns and cells 
        self.cells[i], self.pawns[i] = self:_init_cell(gm, i), {}
        for j = 1, _c do self.pawns[i][j] = {} end
    end
    self:rebuild_cell_metrics()
end

--------------------------------------------------
--- rebuild_cell_metrics
--------------------------------------------------
--- Helper: quad pose 
local function _quad_pose(quad)
    local tl, tr, br, bl = quad and quad[1], quad and quad[2], quad and quad[3], quad and quad[4]
    if not (tl and tr and br and bl) then return end

    local top_w, bot_w     = abs(tr.x - tl.x),  abs(br.x - bl.x)
    local left_h, right_h  = abs(bl.y - tl.y),  abs(br.y - tr.y)
    return 0.5*(bl.x + br.x), 0.5*(bl.y + br.y), 0.5*(top_w + bot_w), 0.5*(left_h + right_h)
end

--- Helper: build cell metrics
local function _build_cell_metrics(self, quad, row_scale)
    local bx, by, qw, qh = _quad_pose(quad);        if not bx then return end
    local _s, _rs = row_scale or 1, min(qw/max(self.cell_w or 1, 1e-6), qh/max(self.cell_h or 1, 1e-6))
    
    return { quad = quad,  anchor_x = bx,  anchor_y  = by,  quad_w = qw,    
        quad_h    = qh,    scale    = _s,  row_scale = _rs }
end

---_______________________________
--- main: rebuild cell metrics 
---_______________________________
function GridZone:rebuild_cell_metrics()
    local projector = self.projector;                   if not projector then return end

    for r_idx = 1, self.n_rows do
        local row      = self.cells and self.cells[r_idx]
        local metrics  = row and row.cell_metrics;       if not row or not metrics then goto continue end 
        for c_idx = 1, self.n_cols do
            local quad = projector:get_cell_quad(r_idx, c_idx)
            metrics[c_idx] = _build_cell_metrics(self, quad, row.row_scale)
        end
        ::continue::
    end
end

-------------------------------------------------
--- get cell metrics | get current cell metrics
-------------------------------------------------
function GridZone:get_cell_metrics(r_idx, c_idx) local row = self.cells[r_idx]; return row and row.cell_metrics and row.cell_metrics[c_idx]  end
function GridZone:get_current_cell_metrics(r_idx, c_idx)
    local base, row   = self:get_cell_metrics(r_idx, c_idx), self.cells[r_idx]
    local card  = row[c_idx]
    local quad  = card:get_projected_quad()
    if not quad then return base end
    return _build_cell_metrics(self, quad, base and base.row_scale or (row and row.row_scale)) or base
end

----------------------------------------------------
--- get projected quad at 
----------------------------------------------------
function GridZone:get_projected_quad_at(r_idx, c_idx)
    local row = self.cells and self.cells[r_idx]
    local card = row and row[c_idx]
    local quad = card and card.get_projected_quad and card:get_projected_quad()
    if quad then
        local T = card.T or {}
        return { { x = quad[1].x + (T.x or 0), y = quad[1].y + (T.y or 0) }, { x = quad[2].x + (T.x or 0), y = quad[2].y + (T.y or 0) }, { x = quad[3].x + (T.x or 0), y = quad[3].y + (T.y or 0) }, { x = quad[4].x + (T.x or 0), y = quad[4].y + (T.y or 0) } }
    end
    local metrics = self:get_cell_metrics(r_idx, c_idx)
    return metrics and _clone_quad(metrics.quad) 
end

------------------------------------
--- remove 
------------------------------------
local function remove_row_slots(row, n_cols)
    if not row then return end
    for c = 1, n_cols do
        local obj = row[c]
        row[c] = nil
        if obj and obj.remove then obj:remove()
        elseif type(obj) == "table" then
            local copy = {}
            for i, item in ipairs(obj) do copy[i] = item end
            for _, item in ipairs(copy) do if item and item.remove then item:remove() end end
        end
    end
end

function GridZone:remove()
    for i = 1, self.n_rows do
        remove_row_slots(self.cells and self.cells[i], self.n_cols)
        remove_row_slots(self.pawns and self.pawns[i], self.n_cols)
    end
    self.cells, self.pawns = nil, nil
    Actor.remove(self)
end

end
