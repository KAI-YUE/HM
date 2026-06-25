local Mutations = require("HMEng.entities.board.boardzone.path.rectangle.mutations")
local Start     = require("HMEng.entities.board.boardzone.path.rectangle.start")

return function(BoardZone, H)
--------------------------------------------------
--- main: build rectangle path
--------------------------------------------------
function BoardZone:build_rectangle_path(inset)
    local zone = self.gridzone
    if not zone then return end

    local path_cfg     = self.config and self.config.path or {}
    local mutation_cfg = path_cfg.mutation or {}

    local n_rows, n_cols = zone.n_rows or 0, zone.n_cols or 0
    local margin         = math.max(0, inset or 0)
    local row_min, row_max = 1 + margin, n_rows - margin
    local col_min, col_max = 1 + margin, n_cols - margin

    if row_min > row_max or col_min > col_max then
        return self:set_path({
            kind = "rectangle",
            inset = margin,
            cells = {},
            nodes = {},
            order = {},
            index_by_cell = {},
            index_by_node = {},
            start_index = 1,
        })
    end

    local path = {
        kind = "rectangle",
        inset = margin,
        cells = {},
        nodes = {},
        order = {},
        index_by_cell = {},
        index_by_node = {},
    }

    for c = col_min, col_max do H.append_path_cell(path, row_min, c) end
    for r = row_min + 1, row_max do H.append_path_cell(path, r, col_max) end
    for c = col_max - 1, col_min, -1 do H.append_path_cell(path, row_max, c) end
    for r = row_max - 1, row_min + 1, -1 do H.append_path_cell(path, r, col_min) end

    H.rebuild_path_views(path)
    Mutations.apply(self, path, row_min, row_max, col_min, col_max, mutation_cfg, H)
    Start.apply(self, path, row_min, row_max, col_min, col_max, H)

    return self:set_path(path)
end
end
