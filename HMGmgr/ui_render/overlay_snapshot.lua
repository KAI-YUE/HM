local C = require("HMfns.animate.color.color_const")

local LG = love.graphics

local cw = C.WHITE
local ck = C.BLACK
local Y, N = true, false

return function(GMgr)
-----------------------------
--- overlay snapshot dirty
----------------------------
--- Helper: mark overlay snapshot dirty
function GMgr:mark_overlay_snapshot_dirty()
    self.overlay_bg_snapshot_dirty = Y
    if self.UI and self.UI.modal_backdrop then self.UI.modal_backdrop.dirty = Y end
end

-----------------------------
--- _overlay_snapshot_shader_config
----------------------------------
function GMgr:_overlay_snapshot_shader_config()
    local OM   = self.UI and self.UI.overlay_menu
    local cfg  = OM and OM.config
    return cfg 
end

-----------------------------
--- _send_overlay_snapshot_shader_uniforms
----------------------------------
function GMgr:_send_overlay_snapshot_shader_uniforms(shader, canvas, cfg)
    if shader:hasUniform("texel_size")  then shader:send("texel_size", { 1 / canvas:getWidth(), 1 / canvas:getHeight() }) end
    if shader:hasUniform("blur_radius") then shader:send("blur_radius", cfg.underlay_blur_radius or 3.0) end
    if shader:hasUniform("dim_color")   then shader:send("dim_color",   cfg.underlay_dim_color or { ck[1], ck[2], ck[3], 0.24 }) end
    if shader:hasUniform("time")        then shader:send("time", cfg.underlay_shader_time or (self._T.real_s) or 0) end
end

-----------------------------
--- _ensure_overlay_snapshot_canvas
----------------------------------
function GMgr:_ensure_overlay_snapshot_canvas()
    local src    = self.g_canvas;                       if not src then return end
    local w,  h  = src:getWidth(), src:getHeight()
    local canvas = self.overlay_bg_canvas
    if canvas and canvas:getWidth() == w and canvas:getHeight() == h then return canvas end 
        
    canvas = LG.newCanvas(w, h)
    self.overlay_bg_canvas         = canvas
    self.overlay_bg_snapshot_dirty = Y
    return canvas
end

-----------------------------
--- _capture_overlay_snapshot
----------------------------------
function GMgr:_capture_overlay_snapshot()
    local canvas = self:_ensure_overlay_snapshot_canvas();       if not canvas then return end
    
    local UI,         overlay     = self.UI, self.UI.overlay_menu
    local old_canvas, old_shader  = LG.getCanvas(), LG.getShader()

    UI.overlay_menu = nil;          LG.setCanvas({ canvas, stencil = Y })
    LG.push();                      LG.origin()
    LG.scale(self.rcfg.s_canvas);   LG.setShader()
    LG.clear(0, 0, 0, 1);           self:_draw_world_field()

    self:obj_render_1by1({ skip_cursor = Y, skip_popups = Y, exclude_overlay = overlay })
    LG.pop()
    UI.overlay_menu = overlay

    if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end
    LG.setShader(old_shader)
    self.overlay_bg_snapshot_dirty = N
end

-----------------------------
---  _draw_overlay_snapshot
----------------------------------
function GMgr:_draw_overlay_snapshot()
    if self.overlay_bg_snapshot_dirty or not self.overlay_bg_canvas then self:_capture_overlay_snapshot() end
    local canvas = self.overlay_bg_canvas;       if not canvas then return N end
    
    local cfg         = self:_overlay_snapshot_shader_config()
    local shader      = cfg and self.t_shaders[cfg.underlay_shader]
    local old_shader  = LG.getShader()
    local r, g, b, a  = LG.getColor()

    LG.push();                                  LG.origin()
    if shader then self:_send_overlay_snapshot_shader_uniforms(shader, canvas, cfg); LG.setShader(shader); end
    LG.setColor(cw);                            LG.draw(canvas, 0, 0)
    LG.setShader(old_shader);                   LG.pop()
    LG.setColor(r, g, b, a)
    return Y
end

end
