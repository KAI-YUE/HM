local PathHelpers       = require("HMEng.entities.board.boardzone.path.shared")
local install_rectangle = require("HMEng.entities.board.boardzone.path.rectangle")

return function(BoardZone)
--------------------------------------------------
--- Helpers: path components
--------------------------------------------------
local function _copy_order(order)
    local out = {}
    for i, node_id in ipairs(order or {}) do out[i] = node_id end
    return out
end

local function _path_from_order(order, kind)
    local path = { kind = kind or "component", nodes = {}, order = _copy_order(order) }
    return PathHelpers.rebuild_path_views(path)
end

local function _occupied(self, node_id)
    local cell = PathHelpers.cell_from_id(node_id)
    local row  = self.gridzone and self.gridzone.cells and self.gridzone.cells[cell.row]
    return row and row[cell.col] ~= nil
end

local function _rectangle_order(row_min, row_max, col_min, col_max)
    local order = {}
    if row_min >= row_max or col_min >= col_max then return order end

    for c = col_min, col_max do order[#order + 1] = PathHelpers.cell_key(row_min, c) end
    for r = row_min + 1, row_max do order[#order + 1] = PathHelpers.cell_key(r, col_max) end
    for c = col_max - 1, col_min, -1 do order[#order + 1] = PathHelpers.cell_key(row_max, c) end
    for r = row_max - 1, row_min + 1, -1 do order[#order + 1] = PathHelpers.cell_key(r, col_min) end
    return order
end

--------------------------------------------------
--- Helper: build separated island rectangles
--------------------------------------------------
local function _island_bounds(self, index, count, inset, gap)
    local usable_cols = self.n_cols - 2*inset - (count - 1)*gap
    local base_w = math.floor(usable_cols/count)
    local extra = usable_cols % count
    local col_min = 1 + inset

    for i = 1, index - 1 do col_min = col_min + base_w + (i <= extra and 1 or 0) + gap end
    local width = base_w + (index <= extra and 1 or 0)
    return 1 + inset, self.n_rows - inset, col_min, col_min + width - 1
end

--------------------------------------------------
--- helper: set path
--------------------------------------------------
function BoardZone:set_path(path)
    if not path then return end
    path.board, path.boardzone = self, self

    if path.cells         == nil then path.cells = {} end
    if path.nodes         == nil then path.nodes = {} end
    if path.order         == nil then path.order = {} end
    if path.index_by_cell == nil then path.index_by_cell = {} end
    if path.index_by_node == nil then path.index_by_node = {} end
    if path.start_index   == nil then path.start_index = 1 end

    PathHelpers.rebuild_path_views(path)
    self.path = path
end

--------------------------------------------------
--- set path components
--------------------------------------------------
function BoardZone:set_paths(paths)
    self.paths = paths or {}
    for i, path in ipairs(self.paths) do
        path.id, path.board, path.boardzone = path.id or ("island_" .. tostring(i)), self, self
    end
    self.path = self.paths[1]
    return self.paths
end

--------------------------------------------------
--- set directed graph paths
--------------------------------------------------
function BoardZone:set_graph_paths(graphs)
    graphs = graphs or {}
    for _, graph in ipairs(graphs) do
        graph.kind, graph.edge_source = graph.kind or "graph", "explicit"
        PathHelpers.rebuild_path_views(graph)
    end
    return self:set_paths(graphs)
end

function BoardZone:set_graph_path(graph)
    return self:set_graph_paths({ graph or {} })
end

--------------------------------------------------
--- split path into party components
--------------------------------------------------
function BoardZone:split_path_components(count)
    local source = self.path and self.path.order or {}
    self.path_template = { kind = self.path and self.path.kind or "component", order = _copy_order(source) }
    if #source == 0 then return self:set_paths({ _path_from_order({}, "component") }) end

    count = math.max(1, math.floor(count or 1))
    if count == 1 then return self:set_paths({ _path_from_order(source, "component") }) end

    local path_cfg = self.config and self.config.path or {}
    local inset = math.max(0, math.floor(path_cfg.inset or 0))
    local gap = math.max(1, math.floor(path_cfg.component_gap or 2))
    local paths = {}

    for i = 1, count do
        local row_min, row_max, col_min, col_max = _island_bounds(self, i, count, inset, gap)
        local order = _rectangle_order(row_min, row_max, col_min, col_max)
        if #order == 0 then break end
        local path = _path_from_order(order, "island")
        path.id = "island_" .. tostring(i)
        paths[#paths + 1] = path
    end
    return self:set_paths(paths)
end

--------------------------------------------------
--- rebuild components from occupied path cells
--------------------------------------------------
function BoardZone:rebuild_path_components()
    local order = self.path_template and self.path_template.order or {}
    local paths, current = {}, nil

    for _, node_id in ipairs(order) do
        if _occupied(self, node_id) then
            current = current or {}
            current[#current + 1] = node_id
        elseif current then
            paths[#paths + 1], current = _path_from_order(current, "component"), nil
        end
    end
    if current then paths[#paths + 1] = _path_from_order(current, "component") end

    if #paths > 1 and _occupied(self, order[1]) and _occupied(self, order[#order]) then
        local merged = {}
        for _, node_id in ipairs(paths[#paths].order) do merged[#merged + 1] = node_id end
        for _, node_id in ipairs(paths[1].order) do merged[#merged + 1] = node_id end
        paths[1] = _path_from_order(merged, "component")
        table.remove(paths)
    end
    return self:set_paths(paths)
end

--------------------------------------------------
--- get component for cell
--------------------------------------------------
function BoardZone:get_path_for_cell(r_idx, c_idx)
    local key = PathHelpers.cell_key(r_idx, c_idx)
    for _, path in ipairs(self.paths or {}) do if path.index_by_cell[key] then return path end end
    local path = self.path
    if path and path.index_by_cell[key] then return path end
end

--------------------------------------------------
--- get outgoing graph cells
--------------------------------------------------
function BoardZone:get_path_next_cells(r_idx, c_idx)
    local path = self:get_path_for_cell(r_idx, c_idx)
    local node = path and path.nodes and path.nodes[PathHelpers.cell_key(r_idx, c_idx)]
    local cells = {}
    local route_next = self.route_adjacency and self.route_adjacency[PathHelpers.cell_key(r_idx, c_idx)] or {}
    for _, node_id in ipairs(route_next) do cells[#cells + 1] = PathHelpers.cell_from_id(node_id) end
    local bridge_next = self.bridge_adjacency and self.bridge_adjacency[PathHelpers.cell_key(r_idx, c_idx)] or {}
    for _, node_id in ipairs(bridge_next) do cells[#cells + 1] = PathHelpers.cell_from_id(node_id) end
    for _, node_id in ipairs(node and node.next or {}) do cells[#cells + 1] = PathHelpers.cell_from_id(node_id) end
    return cells, path
end

--------------------------------------------------
--- cell on path 
--------------------------------------------------
function BoardZone:cell_on_path(r_idx, c_idx)
    local key = PathHelpers.cell_key(r_idx, c_idx)
    if self.route_nodes and self.route_nodes[key] then return Y end
    if self.bridge_nodes and self.bridge_nodes[key] then return Y end
    local path = self:get_path_for_cell(r_idx, c_idx)
    local idx_by_cell = path and path.index_by_cell
    return idx_by_cell and idx_by_cell[key]
end

--------------------------------------------------
--- get_path_cells | get_path_order
--------------------------------------------------
function BoardZone:get_path_cells()            local path = self.path; return path and path.cells; end
function BoardZone:get_path_order()            local path = self.path; return path and path.order; end
function BoardZone:get_path_node(r_idx, c_idx) local path = self.path; return path and path.nodes and path.nodes[PathHelpers.cell_key(r_idx, c_idx)]; end

install_rectangle(BoardZone, PathHelpers)
end
