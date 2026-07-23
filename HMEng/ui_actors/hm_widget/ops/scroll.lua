local renderers = require("HMEng.ui_actors.hm_widget.renderers")

return function(HMWidget)

-----------------------------
--- Scroll
----------------------------------
function HMWidget:scroll(Ctrl, dir, count)
    local renderer = renderers[self.config.renderer]
    if renderer and renderer.scroll then return renderer.scroll(self, Ctrl, dir, count) end
end

function HMWidget:set_scroll_progress(progress)
    local renderer = renderers[self.config.renderer]
    if renderer and renderer.set_progress then return renderer.set_progress(self, progress) end
end

function HMWidget:get_scroll_progress()
    local renderer = renderers[self.config.renderer]
    if renderer and renderer.get_progress then return renderer.get_progress(self) end
end

function HMWidget:ensure_visible(item)
    local renderer = renderers[self.config.renderer]
    if renderer and renderer.ensure_visible then return renderer.ensure_visible(self, item) end
end

end
