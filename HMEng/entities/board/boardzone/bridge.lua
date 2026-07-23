local H = require("HMEng.entities.board.boardzone.path.shared")

local push_unique = H.push_unique

local Y, N = true, false

return function(BoardZone)
--------------------------------------------------
--- Helpers: bridge graph state
--------------------------------------------------
local function _copy_cell(cell) return { row = cell.row, col = cell.col, id = H.cell_key(cell.row, cell.col) } end

local function _path_id(self, cell)
    local path = cell and self:get_path_for_cell(cell.row, cell.col)
    return path and path.id, path
end

local function _blocked_cells(self, source, target)
    local blocked = {}
    for _, path in ipairs(self.paths or {}) do
        for _, cell in ipairs(path.cells or {}) do blocked[H.cell_key(cell.row, cell.col)] = Y end
    end
    for node_id in pairs(self.bridge_nodes or {}) do blocked[node_id] = Y end
    blocked[H.cell_key(source.row, source.col)] = nil
    blocked[H.cell_key(target.row, target.col)] = nil
    return blocked
end

local function _neighbors(self, cell)
    local out = {}
    local deltas = { { -1, 0 }, { 0, 1 }, { 1, 0 }, { 0, -1 } }
    for _, delta in ipairs(deltas) do
        local row, col = cell.row + delta[1], cell.col + delta[2]
        if row >= 1 and col >= 1 and row <= self.n_rows and col <= self.n_cols then out[#out + 1] = { row = row, col = col } end
    end
    return out
end

local function _rebuild_route(previous, target_id)
    local ids, cursor = {}, target_id
    while cursor do ids[#ids + 1], cursor = cursor, previous[cursor] end

    local cells = {}
    for i = #ids, 1, -1 do cells[#cells + 1] = H.cell_from_id(ids[i]) end
    return cells
end

local function _find_corridor(self, source, target, max_length)
    local source_id, target_id = H.cell_key(source.row, source.col), H.cell_key(target.row, target.col)
    local blocked, queue = _blocked_cells(self, source, target), { _copy_cell(source) }
    local previous, distance = { [source_id] = N }, { [source_id] = 0 }
    local cursor = 1

    while cursor <= #queue do
        local cell = queue[cursor]; cursor = cursor + 1
        local cell_id = H.cell_key(cell.row, cell.col)
        if cell_id == target_id then return _rebuild_route(previous, target_id) end

        for _, next_cell in ipairs(_neighbors(self, cell)) do
            local next_id = H.cell_key(next_cell.row, next_cell.col)
            local next_distance = distance[cell_id] + 1
            if previous[next_id] == nil and not blocked[next_id] and next_distance <= max_length then
                previous[next_id], distance[next_id] = cell_id, next_distance
                queue[#queue + 1] = next_cell
            end
        end
    end
end

local function _link(adjacency, from_id, to_id)
    adjacency[from_id] = adjacency[from_id] or {}
    push_unique(adjacency[from_id], to_id)
end

--------------------------------------------------
--- Main: propose and validate bridge
--------------------------------------------------
function BoardZone:propose_bridge(source, target, opts)
    opts = opts or {}
    local source_path = _path_id(self, source)
    local target_path = _path_id(self, target)
    if not source_path or not target_path then return nil, "endpoint_not_on_island" end
    if source_path == target_path then return nil, "same_island" end

    local cells = _find_corridor(self, source, target, opts.max_length or (self.n_rows + self.n_cols))
    if not cells or #cells < 2 then return nil, "no_corridor" end
    self.bridge_serial = (self.bridge_serial or 0) + 1
    return {
        id = "bridge_" .. tostring(self.bridge_serial),
        source = _copy_cell(source), target = _copy_cell(target), cells = cells,
        source_path = source_path, target_path = target_path,
    }
end

function BoardZone:validate_bridge(proposal)
    if not proposal or not proposal.cells or #proposal.cells < 2 then return N, "invalid_proposal" end
    local blocked = _blocked_cells(self, proposal.source, proposal.target)
    for i, cell in ipairs(proposal.cells) do
        local id = H.cell_key(cell.row, cell.col)
        if i > 1 and i < #proposal.cells and blocked[id] then return N, "corridor_blocked" end
        if i > 1 then
            local previous = proposal.cells[i - 1]
            if math.abs(previous.row - cell.row) + math.abs(previous.col - cell.col) ~= 1 then return N, "non_adjacent_cells" end
        end
    end
    return Y
end

--------------------------------------------------
--- Main: commit and remove bridge
--------------------------------------------------
function BoardZone:commit_bridge(proposal)
    local valid, reason = self:validate_bridge(proposal)
    if not valid then return nil, reason end

    local adjacency = self.bridge_adjacency
    for i, cell in ipairs(proposal.cells) do
        local node_id = H.cell_key(cell.row, cell.col)
        if i > 1 and i < #proposal.cells then
            self.bridge_nodes[node_id] = { id = node_id, row = cell.row, col = cell.col, bridge_id = proposal.id }
            local row = self.gridzone and self.gridzone.cells and self.gridzone.cells[cell.row]
            local card = row and row[cell.col]
            if card and card.states then card.states.visible = Y end
        end
        if i > 1 then
            local previous_id = H.cell_key(proposal.cells[i - 1].row, proposal.cells[i - 1].col)
            _link(adjacency, previous_id, node_id)
            _link(adjacency, node_id, previous_id)
        end
    end
    self.bridges[#self.bridges + 1] = proposal
    self.route_version = (self.route_version or 0) + 1
    return proposal
end

function BoardZone:remove_bridge(bridge_id)
    local old_nodes = self.bridge_nodes or {}
    local kept = {}
    for _, bridge in ipairs(self.bridges or {}) do if bridge.id ~= bridge_id then kept[#kept + 1] = bridge end end
    self.bridges, self.bridge_nodes, self.bridge_adjacency = kept, {}, {}
    local bridges = self.bridges
    self.bridges = {}
    for _, bridge in ipairs(bridges) do self:commit_bridge(bridge) end
    self.route_version = (self.route_version or 0) + 1

    for node_id, node in pairs(old_nodes) do
        if not self.bridge_nodes[node_id] and not self.revealed_field_cells[node_id] then
            local row = self.gridzone and self.gridzone.cells and self.gridzone.cells[node.row]
            local card = row and row[node.col]
            if card and card.states then card.states.visible = N end
        end
    end
end

--------------------------------------------------
--- Main: click-driven bridge interaction
--------------------------------------------------
function BoardZone:enable_bridge_interaction(enabled)
    self.bridge_interaction.enabled = enabled ~= N
    if not self.bridge_interaction.enabled then self.bridge_interaction.source, self.bridge_interaction.proposal = nil, nil end
end

function BoardZone:handle_bridge_cell_click(cell)
    local state = self.bridge_interaction
    if not (state and state.enabled and cell and self:cell_on_path(cell.row, cell.col)) then return N end
    local run = self.gm and self.gm.run_loop
    if run and (run.busy or run.turn ~= 1) then return N end

    local path_id = _path_id(self, cell)
    if not path_id then return N end
    if not state.source then state.source = _copy_cell(cell); return Y end

    local source_path = _path_id(self, state.source)
    if source_path == path_id then state.source = _copy_cell(cell); state.proposal = nil; return Y end

    local proposal = self:propose_bridge(state.source, cell)
    state.source = nil
    if not proposal then state.proposal = nil; return N end
    state.proposal = proposal
    local bridge = self:commit_bridge(proposal)
    if bridge then state.proposal = nil; return Y end
    return N
end

end
