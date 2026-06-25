local RNG = require("HMfns.utils.math.rng_utils")

local seeded_rand = RNG.seeded_random

local Shared = {}

--------------------------------------------------
--- cell key | cell_from_id
--------------------------------------------------
function Shared.cell_key(r_idx, c_idx) return tostring(r_idx) .. ":" .. tostring(c_idx); end
function Shared.cell_from_id(node_id)  local r_idx, c_idx = tostring(node_id or ""):match("^(%-?%d+):(%-?%d+)$"); return { row = tonumber(r_idx), col = tonumber(c_idx), id = node_id }; end

--------------------------------------------------
--- push_unique
--------------------------------------------------
function Shared.push_unique(list, value)
    if not list or not value then return list end
    for i = 1, #list do if list[i] == value then return list end; end
    list[#list + 1] = value
    return list
end

--------------------------------------------------
--- ensure_node 
--------------------------------------------------
function Shared.ensure_node(path, r_idx, c_idx)
    local id     = Shared.cell_key(r_idx, c_idx)
    local nodes  = path.nodes
    local node   = nodes[id]

    if not node then
        node = { id = id, row = r_idx, col = c_idx, next = {}, prev = {} }
        nodes[id] = node
    else
        node.id, node.row, node.col  = id, r_idx, c_idx
        node.next, node.prev         = node.next or {}, node.prev or {}
    end
    return node
end

--------------------------------------------------
--- append_path_cell
--------------------------------------------------
function Shared.append_path_cell(path, r_idx, c_idx)
    local node = Shared.ensure_node(path, r_idx, c_idx)
    if path.index_by_node and path.index_by_node[node.id] then return end
    path.order[#path.order + 1] = node.id
    path.index_by_node[node.id] = #path.order
end

--------------------------------------------------
--- seeded_roll
--------------------------------------------------
function Shared.seed_roll(self, key, count)
    if count <= 0 then return 1 end
    return math.floor(seeded_rand(self.gm, tostring(key)) * count) + 1
end

--------------------------------------------------
--- path view rebuild
--------------------------------------------------
--- helper: ensure path storage
local function ensure_path_storage(path)
    local nodes = path.nodes or {}
    local order = path.order or {}

    path.nodes, path.order = nodes, order
    return nodes, order
end

--- helper: seed order from cells
local function seed_order_from_cells(path, order)
    if #order ~= 0 or not path.cells then return end
    for _, cell in ipairs(path.cells) do order[#order + 1] = Shared.cell_key(cell.row, cell.col); end
end

--- helper: rebuild cell views
local function rebuild_cell_views(path, nodes, order)
    local cells, idx_by_cell, idx_by_node, adj = {}, {}, {}, {}

    for i, node_id in ipairs(order) do
        local node = nodes[node_id]
        if not node then
            local r_idx, c_idx = node_id:match("^(%-?%d+):(%-?%d+)$")
            if r_idx and c_idx then node = Shared.ensure_node(path, tonumber(r_idx), tonumber(c_idx)); end
        end

        if node then
            local cell = { row = node.row, col = node.col, id = node.id }
            cells[i], idx_by_cell[node.id], idx_by_node[node.id], adj[node.id] = cell, i, i, {}
        end
    end

    return cells, idx_by_cell, idx_by_node, adj
end

--- helper: reset node links
local function reset_node_links(nodes, adj) for _, node in pairs(nodes) do node.next, node.prev = {}, {}; adj[node.id] = adj[node.id] or {}; end; end

--- helper: ordered loop edges
local function ordered_loop_edges(order)
    local edges, n = {}, #order
    if n <= 1 then return edges end
    for i, from_id in ipairs(order) do edges[#edges + 1] = { from = from_id, to = order[(i % n) + 1] } end
    return edges
end

--- helper: link graph edges
local function link_graph_edges(path, nodes, order, adj)
    local edges = path.edge_source == "explicit" and (path.edges or {}) or ordered_loop_edges(order)
    path.edges = edges

    for _, edge in ipairs(edges) do
        local from_id, to_id = edge.from or edge[1], edge.to or edge[2]
        local from, to       = nodes[from_id], nodes[to_id]
        if from and to and from_id ~= to_id then
            Shared.push_unique(from.next, to_id)
            Shared.push_unique(to.prev, from_id)
            Shared.push_unique(adj[from_id], to_id)
            Shared.push_unique(adj[to_id], from_id)
        end
    end
end

--- helper: resolve path start state
local function resolve_start_state(path, order, idx_by_node, cells)
    local start_node = path.start_node
    if not start_node and path.start_cell then start_node = Shared.cell_key(path.start_cell.row, path.start_cell.col); end
    
    start_node        = start_node or order[1]
    path.start_node   = start_node
    path.start_index  = idx_by_node[start_node] or 1
    path.start_cell   = cells[path.start_index] or cells[1]
end

---___________________________________________
--- main: rebuild_path_views
---___________________________________________
function Shared.rebuild_path_views(path)
    local nodes, order = ensure_path_storage(path)
    seed_order_from_cells(path, order)

    local cells, idx_by_cell, idx_by_node, adj = rebuild_cell_views(path, nodes, order)
    reset_node_links(nodes, adj)
    link_graph_edges(path, nodes, order, adj)

    path.cells, path.adj  = cells, adj
    path.index_by_cell    = idx_by_cell
    path.index_by_node    = idx_by_node
    resolve_start_state(path, order, idx_by_node, cells)
    return path
end

return Shared
