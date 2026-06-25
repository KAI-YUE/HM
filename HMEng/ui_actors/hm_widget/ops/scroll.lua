local renderers = require("HMEng.ui_actors.hm_widget.renderers")

return function(HMWidget)

-----------------------------
--- Scroll
----------------------------------
function HMWidget:scroll(Ctrl, dir, count)
    local renderer = renderers[self.config.renderer]
    if renderer and renderer.scroll then return renderer.scroll(self, Ctrl, dir, count) end
end

end
