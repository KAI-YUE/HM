local abs, exp, log = math.abs, math.exp, math.log
local max, min = math.max, math.min
local DebugFlags = require("HMGmgr.data.global.flags.debug_flags")
local Y, N = true, false

return function (GridZone)
------------------------------------------------------
--- Hard set cards | T
------------------------------------------------------
--- Helper: hard set actor visual transform
local function _hard_set_actor_VT(actor)
    local T, VT = actor and actor.T, actor and actor.VT;        if not (T and VT) then return end
    VT.x, VT.y, VT.w, VT.h, VT.r, VT.scale = T.x, T.y, T.w, T.h, T.r, T.scale
    local v = actor.velocity;                                  if v then v.x, v.y, v.w, v.h, v.r, v.scale = 0, 0, 0, 0, 0, 0 end
    if actor.calculate_parallax then actor:calculate_parallax() end
end

function GridZone:hard_set_cards()  local cells = self.cells; for i, row in pairs(cells) do for j, col in ipairs(row) do col:hard_set_T(); col:calculate_parallax() end end end
function GridZone:hard_set_pawns()  local pawns = self.pawns; if not pawns then return end; self:align_pawns(); for _, row in pairs(pawns) do for _, occupants in pairs(row) do for _, pawn in ipairs(occupants) do if pawn.hard_set_T then pawn:hard_set_T() else _hard_set_actor_VT(pawn) end end end end end
function GridZone:hard_set_T(x, y, w, h)
    local T = self.T
    x, y, w, h = x or T.x, y or T.y, w or T.w, h or T.h
    Actor.hard_set_T(self,x, y, w, h)
    if self.projector then self.projector:build_grid(self.n_rows, self.n_cols, self.T, self.config.projector) end
    self:rebuild_cell_metrics()
    self:align_cards()
    self:hard_set_cards()
    self:hard_set_pawns()
    self.card_layout_dirty, self.pawn_layout_dirty = N, N
end

------------------------------------------------------
--- align_card_at
------------------------------------------------------
--- Helper: sync_projected quad
local function _sync_projected_quad(self, card, r_idx, c_idx, args)
    local projector = self.projector
    if not projector or not card then return end
    card:promote_to_field_card()

    args = args or {}; args.r_idx, args.c_idx = r_idx, c_idx
    local quad = projector:get_local_cell_quad(r_idx, c_idx, card.T)
    if not quad then return end

    card:assign_field_quad(quad)
    local mesh_card = card.children and card.children.mesh_card
    if mesh_card then mesh_card:set_role({ major = card, role_type = "Glued", draw_major = card }) end
end

--- Helper: interacting with 
local function _interacting_with(card)
    local st = card.states
    local drag, focus, hover = st.drag, st.focus, st.hover
    return hover.is or drag.is or focus.is 
end

--__________________
-- main
--__________________
function GridZone:align_card_at(r_idx, c_idx, args)
    local cfg, T, cells   = self.config, self.T, self.cells
    local n_cols, n_rows  = self.n_cols, self.n_rows
    if n_cols <= 0 or n_rows <= 0 or not cells then return end

    local row   = cells[r_idx]
    local card  = row and row[c_idx]
    if not row or not card or _interacting_with(card) then return end

    local gap_x, gap_y   = cfg.gap_x or 0, cfg.gap_y or 0
    local cW,    cH      = self.cell_w, self.cell_h
    local x0,    y0      = T.x, T.y
    local sp, row_depth  = self.shadow_parallax or { x = 0, y = 0 },  row.row_depth or 0
    local cT,    pose    = card.T, row.cell_pose and row.cell_pose[c_idx] or { x = 0, y = 0, r = 0 }

    local cell_x, cell_y = x0 + (c_idx - 1)*(cW + gap_x), y0 + (r_idx - 1)*(cH + gap_y)

    local rx, ry, rr, rs = 0, 0, 0, 1
    local reveal = card.field_reveal
    if reveal then
        rx, ry = reveal.x or 0, reveal.y or 0
        rr, rs = reveal.r or 0, reveal.scale or 1
        reveal.base_scale = reveal.base_scale or cT.scale or 1
    end

    cT.x = cell_x + sp.x*row_depth + (pose.x or 0) + rx
    cT.y = cell_y + sp.y*row_depth + (pose.y or 0) + ry
    cT.r = (T.r or 0) + (pose.r or 0) + rr
    if reveal then cT.scale = reveal.base_scale * rs end

    local csp = card.shadow_parallax
    if csp then cT.x, cT.y = cT.x + csp.x/30, cT.y + csp.y/30 end
    _sync_projected_quad(self, card, r_idx, c_idx, args)
end

------------------------------------------------------
--- align_cards
------------------------------------------------------
function GridZone:align_cards(args) local cfg = self.config; if (cfg.type or "field") == "field" then self:align_filed(args) end; self.card_layout_dirty = N end

-----------------------------------------------------
--- align_pawn_at
------------------------------------------------------
--- Helper: remap foot_y
local function _remap_foot_y(pawn)
    local pT = pawn.T
    return pT.h
end

--- Helper: foot x curve for cols
local function _foot_x_curve_for_cols(pawn, num_cols)
    local p = pawn.params or {}
    if p.foot_x_curve then return p.foot_x_curve end

    local base_cols, base_curve  = p.foot_x_curve_base_cols or 8, p.foot_x_curve_base or 0.63
    local ref_cols, ref_curve    = p.foot_x_curve_ref_cols or 10, p.foot_x_curve_ref or 0.56

    if (num_cols or base_cols) <= base_cols then return base_curve end
    if ref_cols <= base_cols or base_curve <= 0 or ref_curve <= 0 then return base_curve end

    local col_delta = (num_cols or base_cols) - base_cols
    local span_cols = ref_cols - base_cols
    local k         = -log(ref_curve/base_curve)/span_cols
    return base_curve*exp(-k*col_delta)
end

--- Helper: remap foot_x
local function _remap_foot_x(pawn, anchor_x, num_cols)
    local p     = pawn.params or {};            local foot_x  = p.foot_x or 0.5
    local zone  = pawn.zone;                    local pT, zT  = pawn.T, zone.T
    if not zT then return foot_x * pT.w end

    local cx, _w  = zT.x, max(zT.w, 1e-6)
    local side    = (anchor_x - cx)/_w
    local foot_x_curve  = _foot_x_curve_for_cols(pawn, num_cols)
    return foot_x*pT.w*(0.35 + foot_x_curve*side)
end

---_______________________
--- align pawn at 
---_______________________
--- Helper: pawn cell metrics
local function _pawn_cell_metrics(self, r_idx, c_idx) return self:get_current_cell_metrics(r_idx, c_idx) end

function GridZone:align_pawn(pawn, r_idx, c_idx)
    local card  = self.cells[r_idx] and self.cells[r_idx][c_idx]
    if not pawn or not card then return end

    local metrics = _pawn_cell_metrics(self, r_idx, c_idx)
    if not metrics then return end

    local gm, pT, cT          = self.gm, pawn.T, card.T
    local bx, by              = metrics.anchor_x, metrics.anchor_y
    local Fcfg, cell_scale    = gm.Fcfg, metrics.scale or min(metrics.quad_w/max(cT.w, 1e-6), metrics.quad_h/max(cT.h, 1e-6))
    local num_cols            = self.n_cols
    local scale_mode          = (DebugFlags.fps.force_fixed_pawn_scale and "fixed") or pawn.scale_mode or ((pawn.params and pawn.params.scale_mode) or "cell")
    local pawn_scale          = (scale_mode == "fixed") and (pawn.fixed_scale or pT.scale or 1) or cell_scale
    local foot_x, foot_y      = _remap_foot_x(pawn, cT.x + bx, num_cols), _remap_foot_y(pawn)

    local bottom_offset = Fcfg.proj.bottom_offset
    foot_y = foot_y + bottom_offset/2

    local td = pawn.toddle
    local offset = td and td.offset or { x = 0, y = 0, r = 0 }

    local scale_snap = DebugFlags.fps.pawn_scale_snap or 0
    if not pT.scale or abs(pT.scale - pawn_scale) > scale_snap then pT.scale = pawn_scale end
    pT.r     = cT.r + (offset.r or 0)
    pT.x     = cT.x + bx - foot_x + (offset.x or 0)
    pT.y     = cT.y + by - foot_y + (offset.y or 0)
end

function GridZone:align_pawn_at(r_idx, c_idx)
    local row = self.pawns and self.pawns[r_idx]
    for _, pawn in ipairs(row and row[c_idx] or {}) do self:align_pawn(pawn, r_idx, c_idx) end
end

------------------------------------------------------
--- align_pawns
------------------------------------------------------
function GridZone:align_pawns()
    local pawns = self.pawns; 
    if not pawns then return end

    for r_idx = 1, self.n_rows do
        local row = pawns[r_idx]
        for c_idx = 1, self.n_cols do if row and #row[c_idx] > 0 then self:align_pawn_at(r_idx, c_idx) end end
    end
    self.pawn_layout_dirty = N
end

------------------------------------------------------
--- align_filed 
------------------------------------------------------
function GridZone:align_filed(args)
    local n_cols, n_rows, cells = self.n_cols, self.n_rows, self.cells
    if n_cols <= 0 or n_rows <= 0 or not cells then return end

    for i = 1, n_rows do for j = 1, n_cols do self:align_card_at(i, j, args) end end
end


end
