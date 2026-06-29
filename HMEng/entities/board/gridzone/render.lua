local Render, C = require("HMfns.systems.render"), require("HMfns.animate.color.color_const")

local LG = love.graphics
local enqueue_drawable = Render.enqueue_drawable
local Y, N = true, false

return function (GridZone)
-----------------------------------
--- draw 
-----------------------------------
--- Helper: valid field
local function _valid_field(card)
    local st = card.states
    local drag, focus, hover = st.drag, st.focus, st.hover
    return (not drag.is and not focus.is) or (not drag.is and not hover.is)
end

--- Helper: valid pawn
local function _valid_pawn(pawn)
    local st = pawn.states
    local drag, focus, hover = st.drag, st.focus, st.hover
    return (not drag.is and not focus.is) or (not drag.is and not hover.is)
end

--- Helper: status check 
function GridZone:_status_check(gm, type, state)
    local stage = gm.g_stage;  local Tstates = { STS.battle }
end

--- Helper: draw field
function GridZone:draw_field_cell(r_idx, c_idx)
    local row = self.cells and self.cells[r_idx]
    local card = row and row[c_idx]
    if card and _valid_field(card) then
        local preview = self.boardzone and self.boardzone.move_preview
        local key = tostring(r_idx) .. ":" .. tostring(c_idx)
        local old_alpha = card.draw_alpha
        if preview and preview.active and not preview.reachable[key] then card.draw_alpha = (old_alpha or 1)*(preview.dim_alpha or 0.24) end
        card:draw()
        card.draw_alpha = old_alpha
    end
end

function GridZone:draw_field()
    local cells = self.cells
    for r = 1, self.n_rows do 
        local row = cells[r]
        for c = 1, self.n_cols do self:draw_field_cell(r, c) end
    end
end

--------------------------------------------------
--- field focus box
--------------------------------------------------
--- Helper: focused field cell
local function _focused_field_cell(self)
    local ctrl = self.gm and self.gm.CTRL
    local cell = ctrl and ctrl.field_focus_cell;              if cell and cell.row and cell.col then return cell end
    local fct = ctrl and ctrl.focused and ctrl.focused.target
    if fct and fct.zone == self and fct.cell then return fct.cell end
end

--- Helper: inset quad
local function _inset_quad(quad, amt)
    local cx, cy = 0, 0
    for i = 1, 4 do cx, cy = cx + quad[i].x, cy + quad[i].y end
    cx, cy = cx/4, cy/4
    local out = {}
    for i = 1, 4 do local p = quad[i]; out[i] = { x = p.x + (cx - p.x)*amt, y = p.y + (cy - p.y)*amt } end
    return out
end

--- Helper: draw quad line
local function _draw_quad_line(quad)
    LG.line(quad[1].x, quad[1].y, quad[2].x, quad[2].y, quad[3].x, quad[3].y, quad[4].x, quad[4].y, quad[1].x, quad[1].y)
end

--- Helper: draw quad fill
local function _draw_quad_fill(quad) LG.polygon("fill", quad[1].x, quad[1].y, quad[2].x, quad[2].y, quad[3].x, quad[3].y, quad[4].x, quad[4].y) end

--- Helper: hidden field focus cell
local function _hidden_field_focus_cell(self, cell)
    local row = self.cells and cell and self.cells[cell.row]
    local card = row and row[cell.col]
    local st = card and card.states
    if card and st and st.visible == N then return card end
end

--- Helper: draw temp visible hidden focus
local function _draw_temp_visible_hidden_focus(card)
    local st = card and card.states;                  if not st then return end
    local visible, draw_alpha = st.visible, card.draw_alpha
    st.visible, card.draw_alpha = Y, (draw_alpha or 1)*0.48
    if card.draw_without_shadow then card:draw_without_shadow() else card:draw() end
    st.visible, card.draw_alpha = visible, draw_alpha
end

--- Helper: draw field focus box
function GridZone:draw_field_focus_box()
    local cell = _focused_field_cell(self);                  if not (cell and cell.row and cell.col) then return end
    local quad = self:get_projected_quad_at(cell.row, cell.col); if not quad then return end
    local old_r, old_g, old_b, old_a = LG.getColor()
    local old_lw = LG.getLineWidth()
    local hidden_card = _hidden_field_focus_cell(self, cell)
    if hidden_card then _draw_temp_visible_hidden_focus(hidden_card); LG.setColor(1.0, 0.82, 0.28, 0.16); _draw_quad_fill(_inset_quad(quad, 0.04)) end
    LG.setLineWidth(0.055)
    LG.setColor(1.0, 0.82, 0.28, 0.88); _draw_quad_line(quad)
    LG.setLineWidth(0.026)
    LG.setColor(0.05, 0.03, 0.01, 0.75); _draw_quad_line(_inset_quad(quad, 0.10))
    LG.setLineWidth(old_lw)
    LG.setColor(old_r, old_g, old_b, old_a)
end

--- Helper: draw pawn cell
function GridZone:draw_pawn_cell(r_idx, c_idx)
    local row = self.pawns and self.pawns[r_idx]
    for _, pawn in ipairs(row and row[c_idx] or {}) do if _valid_pawn(pawn) then pawn:draw() end end
end

--- Helper: draw pawn 
function GridZone:draw_pawns()
    local pawns = self.pawns
    if not pawns then return end

    for r = 1, self.n_rows do
        local row = pawns[r]
        for c = 1, self.n_cols do self:draw_pawn_cell(r, c) end
    end
end

--______________________
--- Main: draw
--______________________
function GridZone:draw()
    local st   = self.states;       if not st.visible then return end 
    local cfg  = self.config
    local type = cfg.type

    self:bound_me()                           
    enqueue_drawable(self.t_drawable, self)

    if type == "field" then self:draw_field() end
    if type == "field" then self:draw_field_focus_box() end
    self:draw_pawns()
    for _, v in pairs(self.children) do v:draw() end
end

end
