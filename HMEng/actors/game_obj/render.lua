local Render = require("HMfns.systems.render")
local enqueue_drawable = Render.enqueue_drawable

return function (GameObj)
---------------------------------------------------------------------------
-- Draw: draws self, then adds self the the draw hash, then draws all children
---------------------------------------------------------------------------
function GameObj:draw()
    if not self.states.visible then return end
    enqueue_drawable(self.t_drawable, self)
    for _, v in pairs(self.children) do v:draw() end
end

end
