local Render = require("HMfns.systems.render")

local enqueue_drawable = Render.enqueue_drawable

return function (HMPanel)
---____________________________
--- main: draw
---______________________________________
function HMPanel:draw()
    local FR, FRS, UI = self.FR, self.FRS, self.UI
    if FR.f_dr >= FRS.f_dr and not UI.overlay_tut then return end

    FR.f_dr = FRS.f_dr

    if not self.states.visible then return end

    enqueue_drawable(self.t_drawable, self)
    if self.widget and self.widget.draw_self then self.widget:draw_self(); self.widget:draw_children() end
    for _, panel in ipairs(self.switch_attached_panels or {}) do
        if panel and panel.draw_self then panel:draw_self(); panel:draw_children() end
    end
    if self.attached_panel and self.attached_panel.draw_self then self.attached_panel:draw_self(); self.attached_panel:draw_children() end
    self:bound_me()
end

end
