local H = require("HMEng.entities.board.boardzone.path.shared")

local push_unique = H.push_unique

local Y, N = true, false

return function(BoardZone)
--------------------------------------------------
--- Helpers: dynamic route adjacency
--------------------------------------------------
local function _cell_id(row, col) return H.cell_key(row, col) end

local function _is_route_cell(self, row, col)
    local id = _cell_id(row, col)
    return self:get_path_for_cell(row, col) ~= nil
        or (self.route_nodes and self.route_nodes[id] ~= nil)
        or (self.bridge_nodes and self.bridge_nodes[id] ~= nil)
end

local function _link(adjacency, from_id, to_id)
    adjacency[from_id] = adjacency[from_id] or {}
    push_unique(adjacency[from_id], to_id)
end

--------------------------------------------------
--- Main: append a revealed route cell
--------------------------------------------------
function BoardZone:append_revealed_route_cell(row, col)
    if not (row and col) then return end
    local id = _cell_id(row, col)
    if self:get_path_for_cell(row, col) then return self:get_path_for_cell(row, col) end

    self.route_nodes[id] = self.route_nodes[id] or { id = id, row = row, col = col, kind = "revealed" }
    self.route_adjacency[id] = self.route_adjacency[id] or {}

    local deltas = { { -1, 0 }, { 0, 1 }, { 1, 0 }, { 0, -1 } }
    for _, delta in ipairs(deltas) do
        local next_row, next_col = row + delta[1], col + delta[2]
        if _is_route_cell(self, next_row, next_col) then
            local next_id = _cell_id(next_row, next_col)
            _link(self.route_adjacency, id, next_id)
            _link(self.route_adjacency, next_id, id)
        end
    end

    self.route_version = (self.route_version or 0) + 1
    return self.route_nodes[id]
end

--------------------------------------------------
--- Main: movement preview and selection
--------------------------------------------------
function BoardZone:set_move_preview(preview) self.move_preview = preview end
function BoardZone:clear_move_preview() self.move_preview = nil end
function BoardZone:set_path_selection_handler(handler) self.path_selection_handler = handler end

function BoardZone:handle_path_cell_click(cell)
    local handler = self.path_selection_handler
    if not (handler and cell and cell.row and cell.col) then return N end
    return handler(self, cell) and Y or N
end

end
