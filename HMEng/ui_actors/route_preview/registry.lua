local Actor = require("HMEng.actors.actor")

local push = table.insert

local N = false

return function(RoutePreview)
-----------------------------
--- init route preview attributes
-----------------------------
function RoutePreview:init(gm, args)
    args = args or {}
    local RT = gm._room and gm._room.T or { w = 20 }
    Actor.init(self, gm, RT.w - 4.0, 0.55, 3.35, 2.45)

    self.run, self.board, self.route, self.steps = args.run, nil, {}, 0
    self.IREG = gm.R.UIPANEL
    self.states.collide.can, self.states.hover.can = N, N
    if self.IREG then push(self.IREG, self) end
end

-----------------------------
--- remove
-----------------------------
local function _cleanup(tab, obj)
    for i, value in ipairs(tab or {}) do if value == obj then table.remove(tab, i); return end end
end

function RoutePreview:remove()
    _cleanup(self.IREG, self)
    Actor.remove(self)
end

end
