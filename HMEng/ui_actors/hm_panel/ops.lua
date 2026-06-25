local Actor = require("HMEng.actors.actor")

return function (HMPanel)
---____________________________
--- main: move
---______________________________________
function HMPanel:move(dt)
    Actor.move(self, dt)
    if self.widget then self.widget:update(dt); Actor.move(self.widget, dt) end
    if self.attached_panel then self.attached_panel:update(dt); Actor.move(self.attached_panel, dt) end
end

end
