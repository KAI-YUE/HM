local Edges        = require("HMEng.entities.board.boardzone.path.rectangle.mutations.edges")
local Replacements = require("HMEng.entities.board.boardzone.path.rectangle.mutations.replacements")

local N = false

local Mutations = {}

--------------------------------------------------
--- helper: path order splicing
--------------------------------------------------
local function splice_order(path, start_idx, remove_count, new_ids)
    local order, new_order = path.order or {}, {}
    local n, insert_n      = #order, #(new_ids or {})

    for i = 1, start_idx - 1 do new_order[#new_order + 1] = order[i] end
    for i = 1, insert_n do new_order[#new_order + 1] = new_ids[i] end
    for i = start_idx + remove_count, n do new_order[#new_order + 1] = order[i] end

    path.order = new_order
    return path
end

--------------------------------------------------
--- helper: edge mutation application
--------------------------------------------------
local function apply_edge(self, path, edge, row_min, row_max, col_min, col_max, H)
    local cfg      = ((self.config or {}).path or {}).mutation or {}
    local segments = Edges.valid_segments(edge, row_min, row_max, col_min, col_max, cfg.corner_margin)
    local n_seg    = #segments
    if n_seg <= 0 then return end

    local start_idx                 = H.seed_roll(self, "board_path_mutation_turn_" .. tostring(edge), n_seg)
    local start_cell                = segments[start_idx]
    local replacement, remove_count = Replacements.build(edge, start_cell, row_min, row_max, col_min, col_max)
    local first_id                  = replacement[1] and H.cell_key(replacement[1].row, replacement[1].col)
    local order_idx                 = first_id and path.index_by_node[first_id]
    if not order_idx or remove_count <= 0 then return end

    local replacement_ids = {}
    for i = 1, #replacement do
        local cell = replacement[i]
        local node = H.ensure_node(path, cell.row, cell.col)
        replacement_ids[#replacement_ids + 1] = node.id
    end

    splice_order(path, order_idx, remove_count, replacement_ids)
    H.rebuild_path_views(path)
    return {
        edge = edge,
        turn_index = start_idx,
        start_cell = H.cell_from_id(replacement_ids[1]),
        end_cell = H.cell_from_id(replacement_ids[#replacement_ids]),
        remove_count = remove_count,
        replacement = replacement,
    }
end

--------------------------------------------------
--- main: apply rectangle mutations
--------------------------------------------------
function Mutations.apply(self, path, row_min, row_max, col_min, col_max, cfg, H)
    cfg = cfg or {}
    if cfg.enabled == N then return path end

    Edges.pick(self, path, row_min, row_max, col_min, col_max, cfg, H)

    local mutations, applied = path.mutations or { edge_count = 0, edges = {} }, {}
    for _, edge in ipairs(mutations.edges or {}) do
        local entry = apply_edge(self, path, edge, row_min, row_max, col_min, col_max, H)
        if entry then applied[#applied + 1] = entry end
    end

    mutations.applied    = applied
    mutations.edge_count = #applied
    path.mutations       = mutations
    return path
end

return Mutations
