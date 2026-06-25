local Render     = require("HMfns.systems.render")
local renderers  = require("HMEng.ui_actors.hm_widget.renderers")
local DrawOrder  = require("HMEng.ui_actors.hm_widget.draw_order")

local enqueue_drawable  = Render.enqueue_drawable

return function (HMWidget)

---____________________________
--- main: draw_self
---______________________________________
function HMWidget:draw_self(opts)
    if not self.states.visible then return end

    local cfg = self.config

    local renderer = renderers[cfg.renderer] or renderers.stitched_rect
    local enqueue_before_draw = (cfg.renderer == "stroked_page" or cfg.renderer == "art_page" or cfg.renderer == "scrollable_pages")
    local enqueue_draw = not (opts and opts.shadow_only)

    if enqueue_draw and enqueue_before_draw then enqueue_drawable(self.t_drawable, self) end
    renderer.draw(self, opts)
    if not (opts and opts.shadow_only) then self:draw_text_overlay() end

    if enqueue_draw and not enqueue_before_draw then enqueue_drawable(self.t_drawable, self) end
    if enqueue_draw then self:bound_me() end
end

---____________________________
--- main: draw
---______________________________________
function HMWidget:draw(opts)
    self:draw_self(opts)
    if not (opts and (opts.shadow_only or opts.skip_shadow)) then self:draw_children() end
end

---____________________________
--- main: draw_children
---______________________________________
function HMWidget:draw_children()
    local renderer = renderers[self.config.renderer] or renderers.stitched_rect
    if renderer and renderer.draws_children then return end
    DrawOrder.draw(self.children)
end

end
