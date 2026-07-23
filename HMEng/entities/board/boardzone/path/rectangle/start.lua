local Start = {}

------------------------------------------------------
--- apply, set rectangle path start
------------------------------------------------------
--- helper: rotate_to_start
local function rotate_to_start(path, start_idx, H)
    local order = path.order or {}
    local n     = #order
    if n <= 1 or not start_idx or start_idx <= 1 or start_idx > n then H.rebuild_path_views(path); return path; end

    local rotated = {}
    for i = 0, n - 1 do rotated[i + 1] = order[((start_idx + i - 1) % n) + 1] end

    path.order = rotated
    H.rebuild_path_views(path)
    return path
end


--- helper: start cell selection
local function pick_cell(self, path, row_min, row_max, col_min, col_max, H)
    local edges = { top = {}, bottom = {} }

    for c = col_min, col_max do
        edges.top[#edges.top + 1]       = { row = row_min, col = c }
        edges.bottom[#edges.bottom + 1] = { row = row_max, col = c }
    end

    local edge_name   = (H.seed_roll(self, "board_path_start_edge", 2) == 1) and "top" or "bottom"
    local edge_cells  = edges[edge_name]
    local edge_idx    = H.seed_roll(self, "board_path_start_cell", #edge_cells - 2)
    local start_cell  = edge_cells[edge_idx + 1]
    local start_node  = start_cell and H.cell_key(start_cell.row, start_cell.col)
    local start_index = start_node and path.index_by_node[start_node] or 1

    path.start_edge, path.start_node  = edge_name, start_node
    path.start_cell, path.start_index = start_cell, start_index or 1
    return path
end

---_____________________________________________
--- main: apply, set rectangle path start
---_____________________________________________
function Start.apply(self, path, row_min, row_max, col_min, col_max, H)
    pick_cell(self, path, row_min, row_max, col_min, col_max, H)
    rotate_to_start(path, path.start_index, H)

    path.start_index = 1
    path.start_node  = path.order[1]
    path.start_cell  = path.cells[1]
    return path
end

return Start
