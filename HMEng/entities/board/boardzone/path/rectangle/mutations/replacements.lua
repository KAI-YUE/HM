local Replacements = {}

--------------------------------------------------
--- helper: directional replacements
--------------------------------------------------
--- helper: top
local function top(start_cell, row_min, row_max, col_min, col_max)
    local r_idx, c_idx = start_cell.row, start_cell.col
    local cells        = { { row = r_idx, col = c_idx } }
    for c = c_idx, col_max do cells[#cells + 1] = { row = r_idx - 1, col = c } end
    cells[#cells + 1] = { row = r_idx, col = col_max }
    return cells, (col_max - c_idx + 1)
end

--- helper: right 
local function right(start_cell, row_min, row_max, col_min, col_max)
    local r_idx, c_idx = start_cell.row, start_cell.col
    local cells        = { { row = r_idx, col = c_idx } }
    for r = r_idx, row_max do cells[#cells + 1] = { row = r, col = c_idx + 1 } end
    cells[#cells + 1]  = { row = row_max, col = c_idx }
    return cells, (row_max - r_idx + 1)
end

--- Helper: bottom
local function bottom(start_cell, row_min, row_max, col_min, col_max)
    local r_idx, c_idx = start_cell.row, start_cell.col
    local cells        = { { row = r_idx, col = c_idx } }
    for c = c_idx, col_min, -1 do cells[#cells + 1] = { row = r_idx + 1, col = c } end
    cells[#cells + 1] = { row = r_idx, col = col_min }
    return cells, (c_idx - col_min + 1)
end

--- Helper: left 
local function left(start_cell, row_min, row_max, col_min, col_max)
    local r_idx, c_idx = start_cell.row, start_cell.col
    local cells        = { { row = r_idx, col = c_idx } }
    for r = r_idx, row_min + 1, -1 do cells[#cells + 1] = { row = r, col = c_idx - 1 } end
    cells[#cells + 1] = { row = row_min + 1, col = c_idx }
    return cells, (r_idx - row_min)
end

--------------------------------------------------
--- main: build mutation replacement
--------------------------------------------------
function Replacements.build(edge, start_cell, row_min, row_max, col_min, col_max)
    if     edge == "top"    then return top(start_cell, row_min, row_max, col_min, col_max)
    elseif edge == "right"  then return right(start_cell, row_min, row_max, col_min, col_max)
    elseif edge == "bottom" then return bottom(start_cell, row_min, row_max, col_min, col_max)
    elseif edge == "left"   then return left(start_cell, row_min, row_max, col_min, col_max) end
    return {}, 0
end

return Replacements
