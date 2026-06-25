local max, min = math.max, math.min

local Y, N = true, false

local Edges = {}

-----------------------------------------------
--- pick (mutation edges)
-----------------------------------------------
--- helper: mutation edge candidates
local function candidates(self, row_min, row_max, col_min, col_max)
    local zone,   edges  = self.gridzone or {}, {}
    local n_rows, n_cols = zone.n_rows or 0, zone.n_cols or 0

    if row_min > 1      and (col_max - col_min) >= 1 then edges[#edges + 1] = "top" end
    if col_max < n_cols and (row_max - row_min) >= 1 then edges[#edges + 1] = "right" end
    if row_max < n_rows and (col_max - col_min) >= 1 then edges[#edges + 1] = "bottom" end
    if col_min > 1      and (row_max - row_min) >= 1 then edges[#edges + 1] = "left" end

    return edges
end


---_______________________________________
--- main: pick, pick mutation edges
---_______________________________________
function Edges.pick(self, path, row_min, row_max, col_min, col_max, cfg, H)
    local available = candidates(self, row_min, row_max, col_min, col_max)
    local n_avail   = #available;      if n_avail == 0 then path.mutations = { edge_count = 0, edges = {} }; return path end

    local max_edges     = min(cfg.max_edges or 3, n_avail)
    local edge_count    = min(H.seed_roll(self, "mutation_edge_count", 3), max_edges)
    local chosen, edges = {}, {}

    for i = 1, edge_count do
        local idx  = H.seed_roll(self, "board_path_mutation_edge_" .. tostring(i), #available)
        local edge = table.remove(available, idx)
        if edge then chosen[edge], edges[#edges + 1] = Y, edge end
    end

    path.mutations = { edge_count = #edges, edges = edges, by_edge = chosen }
    return path
end

-------------------------------------------------
--- valid mutation segments
-------------------------------------------------
--- helper: mutation edge segments
local function segment_cells(edge, row_min, row_max, col_min, col_max)
    local cells = {}
    if     edge == "top"    then for c = col_min, col_max - 1 do cells[#cells + 1] = { row = row_min, col = c } end
    elseif edge == "right"  then for r = row_min, row_max - 1 do cells[#cells + 1] = { row = r, col = col_max } end
    elseif edge == "bottom" then for c = col_max, col_min + 1, -1 do cells[#cells + 1] = { row = row_max, col = c } end
    elseif edge == "left"   then for r = row_max, row_min + 1, -1 do cells[#cells + 1] = { row = r, col = col_min } end end
    return cells
end

--- Helper: corner_margin_ok
local function corner_margin_ok(edge, cell, row_min, row_max, col_min, col_max, margin)
    margin = max(0, margin or 0);               if margin <= 0 then return Y end

    if edge == "top" or edge == "bottom" then
        local left_gap  = (cell.col or col_min) - col_min
        local right_gap = col_max - (cell.col or col_max)
        return left_gap >= margin and right_gap >= margin
    elseif edge == "left" or edge == "right" then
        local top_gap    = (cell.row or row_min) - row_min
        local bottom_gap = row_max - (cell.row or row_max)
        return top_gap >= margin and bottom_gap >= margin
    end

    return N
end

---_______________________________________
--- main: valid mutation segments
---_______________________________________
function Edges.valid_segments(edge, row_min, row_max, col_min, col_max, margin)
    local all, valid = segment_cells(edge, row_min, row_max, col_min, col_max), {}
    for i = 1, #all do
        local cell = all[i]
        if corner_margin_ok(edge, cell, row_min, row_max, col_min, col_max, margin) then valid[#valid + 1] = cell; end
    end
    return valid
end

return Edges
