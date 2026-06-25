return function(RoutePreview)
-----------------------------
--- set preview
-----------------------------
function RoutePreview:set_preview(board, route, steps)
    self.board, self.route, self.steps = board, route or {}, math.max(0, math.floor(steps or 0))
    self.states.visible = self.steps > 0 and #self.route > 1
end

end
