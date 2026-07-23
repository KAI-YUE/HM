local max = math.max

return function(RoutePreview)
-----------------------------
--- helper: minimap coordinates
-----------------------------
function RoutePreview:_cell_point(cell)
    local board, T = self.board, self.T
    local rows, cols = max(board and board.n_rows or 1, 1), max(board and board.n_cols or 1, 1)
    local pad, footer = 0.28, 0.38
    local w, h = T.w - 2*pad, T.h - 2*pad - footer
    return pad + ((cell.col - 1)/max(cols - 1, 1))*w, pad + ((cell.row - 1)/max(rows - 1, 1))*h
end

end
