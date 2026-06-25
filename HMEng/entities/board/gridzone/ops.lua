local Actor = require("HMEng.actors.actor")

local Y, N = true, false 

return function (GridZone)
-------------------------------------------------------
--- update | move 
-------------------------------------------------------
--- Helper: mark layout dirty
function GridZone:mark_card_layout_dirty() local gm = self.gm; if gm and gm.mark_zone_layout_dirty then gm:mark_zone_layout_dirty(self, "card"); return end; self.card_layout_dirty = Y; self:wake_move() end
function GridZone:mark_pawn_layout_dirty() local gm = self.gm; if gm and gm.mark_zone_layout_dirty then gm:mark_zone_layout_dirty(self, "pawn"); return end; self.pawn_layout_dirty = Y; self:wake_move() end
function GridZone:mark_layout_dirty()      local gm = self.gm; if gm and gm.mark_zone_layout_dirty then gm:mark_zone_layout_dirty(self); return end; self:mark_card_layout_dirty(); self:mark_pawn_layout_dirty() end

--- Helper: card layout is live
local function _card_layout_is_live(self)
    local cfg = self.config or {}
    if self.focus_projection_pending or (self.focus_projection_state_dirty and self:focus_projection_state_dirty()) then return Y end
    for r_idx = 1, self.n_rows do
        local row = self.cells and self.cells[r_idx]
        for c_idx = 1, self.n_cols do
            local card, st = row and row[c_idx]
            st = card and card.states
            if st and ((st.hover and st.hover.is) or (st.drag and st.drag.is) or (st.focus and st.focus.is)) then return Y end
        end
    end
    return cfg.live_layout == Y
end

--- Helper: static move pending
function GridZone:static_move_pending() return Actor.static_move_pending(self) or _card_layout_is_live(self) end

--- Helper: flush layout
function GridZone:flush_layout(dt)
    if self.refresh_focus_projection_state and self:refresh_focus_projection_state() then self.card_layout_dirty, self.pawn_layout_dirty = Y, Y end
    local live, was_live = _card_layout_is_live(self), self.card_layout_live
    self.card_layout_live = live
    if self.card_layout_dirty or live or was_live then self:align_cards({ dt = dt }); self.card_layout_dirty = N; if self.focus_projection_pending then self.pawn_layout_dirty = Y end end
    if self.pawn_layout_dirty then self:align_pawns(); self.pawn_layout_dirty = N end
end

---____________________
--- main
---____________________
function GridZone:update(dt) end
function GridZone:move(dt)
    local was_new_align = self.new_align
    local moved = Actor.move(self, dt)
    local focus_dirty = self.focus_projection_pending or (self.focus_projection_state_dirty and self:focus_projection_state_dirty())
    if not moved and not (self.card_layout_dirty or self.pawn_layout_dirty or self.card_layout_live or self.pawn_layout_live or focus_dirty) then return end
    if was_new_align then self:mark_layout_dirty() end
    self:flush_layout(dt)
end

-----------------------------------------------
--- Set zone sts 
-----------------------------------------------
function GridZone:set_zone_sts(r_idx, c_idx)
    local row  = self.cells[r_idx]
    local card = row[c_idx]
    card.tilt_shadow, card.cbuffer = Y, 0
end

--------------------------------------------------
--- emplace card
--------------------------------------------------
function GridZone:emplace_card(card, r_idx, c_idx)
    local gm,   cfg, _sc  = self.gm, self.config, self.cards
    local ctype, _r, _c   = cfg.type, r_idx or 0, c_idx or 0

    self.cells[r_idx][c_idx] = card

    card:set_zone(self)
    if card.set_cell then card:set_cell(r_idx, c_idx) end
    self:set_zone_sts(r_idx, c_idx)
    
    self:align_card_at(r_idx, c_idx)
    card:build_front_canvas()        -- JIT canvas
    card:calculate_parallax()
    self.card_layout_dirty = N
end

---------------------------------------------
--- emplace pawn 
---------------------------------------------
function GridZone:emplace_pawn(pawn, r_idx, c_idx)
    local row   = self.pawns and self.pawns[r_idx]
    local cells = self.cells and self.cells[r_idx]
    
    if not row or not cells or not cells[c_idx] then return end
    local occupants = row[c_idx]
    for _, occupant in ipairs(occupants) do if occupant == pawn then return pawn end end

    occupants[#occupants + 1] = pawn
    pawn:place_on_cell(self, r_idx, c_idx)
    if pawn == self.gm.field_pawn and self.mark_focus_projection_dirty then self:mark_focus_projection_dirty() end
    self:align_pawn(pawn, r_idx, c_idx)
    self.pawn_layout_dirty = N
    return pawn
end

--------------------------------------------------
--- remove card
--------------------------------------------------
--- Helper: _remove_card_from_row
local function _remove_card_from_row(row, n_cols, card)
    for c = 1, n_cols do
        local cur = row[c]
        if cur and (not card or cur == card) then cur:detach_from_zone(); row[c] = nil; return cur end
    end
end

---________________________________
--- main: remove card 
---________________________________
function GridZone:remove_card(card)
    local cells = self.cells;           if not cells then return end
    for r = 1, self.n_rows do
        local row      = cells[r]
        local removed  = _remove_card_from_row(row, self.n_cols, card)
        if removed then self:mark_card_layout_dirty(); return removed end
    end
end

--------------------------------------------------
--- remove pawn
--------------------------------------------------
--- Helper: target pawn 2b removed 
local function target_pawn_2b_removed(cur, occupants, index)
    cur.board, cur.zone, cur.parent = nil, nil, nil
    cur.layered_parallax = { x = 0, y = 0 }
    if cur.clear_cell then cur:clear_cell() end
    if cur.gm and cur.gm.refresh_render_context then cur.gm:refresh_render_context(cur) end
    table.remove(occupants, index)
    return cur
end

--- Helper: _remove_pawn_from_cell
local function _remove_pawn_from_cell(pawns, pawn)
    local cell = pawn and pawn.cell or {}
    local row  = pawns and pawns[cell.row]
    local occupants = row and row[cell.col]
    for i, cur in ipairs(occupants or {}) do if cur == pawn then return target_pawn_2b_removed(cur, occupants, i) end end
end

---________________________________
--- main: remove pawn
---________________________________
function GridZone:remove_pawn(pawn)
    local pawns = self.pawns;                    if not pawns or not pawn then return end
    local removed = _remove_pawn_from_cell(pawns, pawn)
    if removed then self:mark_pawn_layout_dirty() end
    return removed
end

end
