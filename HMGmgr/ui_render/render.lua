local C   = require("HMfns.animate.color.color_const")
local LG  = love.graphics

local cw   = C.WHITE
local Y, N = true, false

-----------------------------
--- draw
----------------------------------
--- Helper: render main scene layers
local function render_main_layers(self, transition_hides_scene, tunnel_hides_scene, underlay_mode)
    if transition_hides_scene and not (tunnel_hides_scene and self._page_tunnel_renders_hold_scene and self:_page_tunnel_renders_hold_scene()) then
    elseif self:_modal_backdrop_config()   and self:_draw_modal_backdrop(underlay_mode) then  self:_render_modal_layers()
    elseif underlay_mode == "snapshot"     and self:_draw_overlay_snapshot()            then  self:_render_overlay_layers()
    elseif underlay_mode == "hidden"                                                then  self:_render_overlay_layers()
    else   self:_draw_world_field(); self:obj_render_1by1() end
end

return function (GMgr)
function GMgr:draw()
    local UI = self.UI;                          if UI.suspended then UI.suspended = N; return end
    local FRS, Fs = self.FRS, self.Fs;           FRS.f_dr = FRS.f_dr + 1

    Fs.wipe_drawable(self)
    if UI.overlay_tut and not UI.overlay_menu then self.under_overlay = Y end

    LG.setCanvas({ self.g_canvas, stencil = Y }); LG.push()
    LG.scale(self.rcfg.s_canvas);                 LG.setShader()
    LG.clear(0, 0, 0, 1)

    local tunnel_hides_scene     = self._page_tunnel_hides_scene and self:_page_tunnel_hides_scene()
    local animator_hides_scene   = self._page_animator_hides_scene and self:_page_animator_hides_scene()
    local transition_hides_scene = tunnel_hides_scene or animator_hides_scene
    local underlay_mode          = self:_overlay_underlay_mode()
    render_main_layers(self, transition_hides_scene, tunnel_hides_scene, underlay_mode)

    self:_draw_load_transition_snapshot()
    self:_draw_page_tunnel_transition()
    self:_draw_page_animator_transition()
    LG.pop()

    LG.setCanvas();                               LG.push()
    LG.setShader();                               LG.setColor(cw)

    local canvas_w, canvas_h = self.g_canvas:getDimensions()
    LG.draw(self.g_canvas, 0, 0, 0, LG.getWidth()/canvas_w, LG.getHeight()/canvas_h)
    self:_draw_resolution_preview_screen_overlay()
    LG.pop();                                     LG.setCanvas()
    self:debug_pointer_grid()
    self:debug_simulated_controller()
    self:debug_fps()
end

require("HMGmgr.ui_render.misc")(GMgr)
require("HMGmgr.ui_render.overlay_layers")(GMgr)
require("HMGmgr.ui_render.scene_layers")(GMgr)
require("HMGmgr.ui_render.overlay_snapshot")(GMgr)
require("HMGmgr.ui_render.modal_backdrop")(GMgr)
require("HMGmgr.ui_render.transitions")(GMgr)

end
