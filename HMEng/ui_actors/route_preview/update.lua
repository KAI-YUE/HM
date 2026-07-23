local Y, N = true, false

return function(RoutePreview)
-----------------------------
--- update
-----------------------------
function RoutePreview:update(dt)
    local run = self.run
    if run and (run.busy or run.turn ~= 1) then self.states.visible = N end
end

end
