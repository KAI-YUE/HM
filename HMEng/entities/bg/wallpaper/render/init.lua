local Render      = require("HMfns.systems.render")
local C, LG       = require("HMfns.animate.color.color_const"), love.graphics

local enqueue_drawable   = Render.enqueue_drawable
local push_draw_trans    = Render.push_actor_draw_transform

local cw = C.WHITE

return function (Wallpaper)
--------------------------------------------------
--- draw
--------------------------------------------------
function Wallpaper:draw()
    local st = self.states;                       if not st.visible then return end
    self:sync_to_screen()
    self:bound_me()
    
    enqueue_drawable(self.t_drawable, self)
    if not (self.image and self.quad) then self:sync_atlas() end
    if not (self.image and self.quad) then return end

    push_draw_trans(self)
    local old_shader    = LG.getShader()
    local _, _, qw, qh  = self.quad:getViewport()

    local T     = self.T
    local w, h  = T.w, T.h

    self:apply_shader()
    local drift_on  = self:drift_enabled()
    local drift     = self.config.drift or self.config.parallax
    local layers    = drift_on and drift and drift.layers
    
    if layers then  for _, layer in ipairs(layers) do self:draw_wallpaper_layer(qw, qh, w, h, layer) end
    else            self:draw_wallpaper_layer(qw, qh, w, h) end
    
    LG.setShader(old_shader)
    LG.pop()
    LG.setColor(cw)

    for _, child in pairs(self.children) do child:draw() end
end

end
