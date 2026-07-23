local Render = require("HMfns.systems.render")

local enqueue_drawable = Render.enqueue_drawable

return function (BoardZone)
--------------------------------------------------
--- draw path field
--------------------------------------------------
function BoardZone:draw_path_field()
    local zone = self.gridzone
    if not zone then return end
    local paths = self.paths
    if not paths or #paths == 0 then paths = { self.path } end

    for _, path in ipairs(paths) do
        for _, cell in ipairs(path and path.cells or {}) do
            if zone.config and zone.config.type == "field" then zone:draw_field_cell(cell.row, cell.col) end
        end
    end
end

--------------------------------------------------
--- draw revealed non-path field
--------------------------------------------------
function BoardZone:draw_revealed_field()
    local zone = self.gridzone
    if not zone then return end
    for _, cell in pairs(self.revealed_field_cells or {}) do zone:draw_field_cell(cell.row, cell.col) end
end

--------------------------------------------------
--- draw bridge field
--------------------------------------------------
function BoardZone:draw_bridge_field()
    local zone = self.gridzone
    if not zone then return end
    for _, node in pairs(self.bridge_nodes or {}) do zone:draw_field_cell(node.row, node.col) end
end

--------------------------------------------------
--- draw debug hidden field
--------------------------------------------------
local function _draw_debug_hidden_card(card)
    local st = card and card.states
    if not st or st.visible then return end

    local visible, draw_alpha = st.visible, card.draw_alpha
    st.visible, card.draw_alpha = true, (draw_alpha or 1)*0.35
    card:draw()
    st.visible, card.draw_alpha = visible, draw_alpha
end

function BoardZone:draw_debug_hidden_field()
    local zone, gm = self.gridzone, self.gm
    local held_keys = gm and gm.CTRL and gm.CTRL.held_keys
    if not (zone and gm.debug and gm.debug.on and held_keys and held_keys.f) then return end

    for r_idx = 1, zone.n_rows do
        local row = zone.cells and zone.cells[r_idx]
        for c_idx = 1, zone.n_cols do _draw_debug_hidden_card(row and row[c_idx]) end
    end
end

--------------------------------------------------
--- draw path pawns
--------------------------------------------------
function BoardZone:draw_path_pawns()
    local zone = self.gridzone
    if not zone then return end
    local paths = self.paths
    if not paths or #paths == 0 then paths = { self.path } end

    for _, path in ipairs(paths) do
        for _, cell in ipairs(path and path.cells or {}) do zone:draw_pawn_cell(cell.row, cell.col) end
    end
end

--------------------------------------------------
--- draw bridge pawns
--------------------------------------------------
function BoardZone:draw_bridge_pawns()
    local zone = self.gridzone
    if not zone then return end
    for _, node in pairs(self.bridge_nodes or {}) do zone:draw_pawn_cell(node.row, node.col) end
end

--------------------------------------------------
--- draw revealed route pawns
--------------------------------------------------
function BoardZone:draw_revealed_route_pawns()
    local zone = self.gridzone
    if not zone then return end
    for _, node in pairs(self.route_nodes or {}) do zone:draw_pawn_cell(node.row, node.col) end
end

--------------------------------------------------
--- draw non-path pawns
--------------------------------------------------
function BoardZone:draw_non_path_pawns()
    local zone = self.gridzone
    if not zone or not zone.pawns then return end

    for r_idx = 1, zone.n_rows do
        for c_idx = 1, zone.n_cols do
            if not self:cell_on_path(r_idx, c_idx) then zone:draw_pawn_cell(r_idx, c_idx) end
        end
    end
end

--------------------------------------------------
--- draw
--------------------------------------------------
function BoardZone:draw()
    local st = self.states;                     if not st.visible then return end

    self:bound_me()
    enqueue_drawable(self.t_drawable, self)

    local path, gzone, bg_decor = self.path, self.gridzone, self.bg_decor
    if path and path.cells then
        self:draw_path_field()
        self:draw_bridge_field()
        self:draw_revealed_field()
        self:draw_debug_hidden_field()
        if bg_decor then bg_decor:draw() end
        self:draw_non_path_pawns()
        self:draw_path_pawns()
        self:draw_bridge_pawns()
        self:draw_revealed_route_pawns()
    end
    -- self.gridzone:draw() 

    for _, v in pairs(self.children) do v:draw() end
end

end
