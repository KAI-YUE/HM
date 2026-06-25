local Actor = require("HMEng.actors.actor")
local TextUpdate = require("HMEng.ui_actors.hm_widget.renderers.text.update")
local renderers = require("HMEng.ui_actors.hm_widget.renderers")

return function (HMWidget)
-----------------------------
-- Update loop
-----------------------------
function HMWidget:update_text() TextUpdate.update(self) end
function HMWidget:update(dt)
    self:update_text()
    local renderer = renderers[self.config.renderer]
    if renderer and renderer.update then renderer.update(self, dt) end
    for _, child in pairs(self.children or {}) do
        if child.update then child:update(dt) end
        Actor.move(child, dt)
    end
end

end
