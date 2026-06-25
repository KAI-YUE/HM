local C = require("HMfns.animate.color.color_const")

local LG = love.graphics

local cw = C.WHITE
local ck = C.BLACK
local Y, N = true, false

return function(GMgr)
-----------------------------
--- modal backdrop dirty
----------------------------
--- Helper: clear modal backdrop
function GMgr:clear_modal_backdrop(owner)
    local bg = self.UI and self.UI.modal_backdrop
    if not bg or (owner and bg.owner ~= owner) then return end
    self.UI.modal_backdrop = nil
end

--- Helper: mark modal backdrop dirty
function GMgr:mark_modal_backdrop_dirty(owner)
    local bg = self.UI and self.UI.modal_backdrop;       if not bg or (owner and bg.owner ~= owner) then return end
    bg.dirty = Y
end

--- Helper: _modal_backdrop_config
function GMgr:_modal_backdrop_config()
    local bg = self.UI and self.UI.modal_backdrop
    local owner = bg and bg.owner
    if owner and owner.REMOVED then self.UI.modal_backdrop = nil; return end
    return bg
end

--- Helper: new_modal_backdrop_canvas
local function new_modal_backdrop_canvas(w, h)
    local ok, canvas = pcall(LG.newCanvas, w, h, { mipmaps = "manual" })
    if ok and canvas then return canvas end
    return LG.newCanvas(w, h)
end

--- Helper: update_modal_backdrop_mipmaps
local function update_modal_backdrop_mipmaps(canvas)
    if canvas and canvas.generateMipmaps then pcall(canvas.generateMipmaps, canvas) end
end

--- Helper: _ensure_modal_backdrop_canvas
function GMgr:_ensure_modal_backdrop_canvas()
    local src = self.g_canvas;                         if not src then return end
    local w, h = src:getWidth(), src:getHeight()
    local canvas = self.modal_bg_canvas
    if not canvas or canvas:getWidth() ~= w or canvas:getHeight() ~= h then
        canvas = new_modal_backdrop_canvas(w, h)
        self.modal_bg_canvas = canvas
        if self.UI and self.UI.modal_backdrop then self.UI.modal_backdrop.dirty = Y end
    end
    return canvas
end

--- Helper: _render_modal_backdrop_source
function GMgr:_render_modal_backdrop_source(underlay_mode)
    if underlay_mode == "snapshot" and self:_draw_overlay_snapshot() then
        self:_render_overlay_layers({ skip_cursor = Y, skip_popups = Y })
    elseif underlay_mode == "hidden" then
        self:_render_overlay_layers({ skip_cursor = Y, skip_popups = Y })
    else
        self:_draw_world_field()
        self:obj_render_1by1({ skip_cursor = Y, skip_popups = Y })
    end
end

--- Helper: _capture_modal_backdrop
function GMgr:_capture_modal_backdrop(underlay_mode)
    local bg = self:_modal_backdrop_config();           if not bg then return end
    local canvas = self:_ensure_modal_backdrop_canvas(); if not canvas then return end
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()

    LG.setCanvas({ canvas, stencil = Y })
    LG.push()
    LG.origin()
    LG.scale(self.rcfg.s_canvas)
    LG.setShader()
    LG.clear(0, 0, 0, 1)
    self:_render_modal_backdrop_source(underlay_mode)
    LG.pop()
    update_modal_backdrop_mipmaps(canvas)

    if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end
    LG.setShader(old_shader)
    bg.dirty = N
end

--- Helper: _draw_modal_backdrop
function GMgr:_draw_modal_backdrop(underlay_mode)
    local bg = self:_modal_backdrop_config();      if not bg then return N end
    if bg.dirty or not self.modal_bg_canvas then self:_capture_modal_backdrop(underlay_mode) end

    local canvas = self.modal_bg_canvas;           if not canvas then return N end
    local shader = self.t_shaders and self.t_shaders[bg.shader or "_modal_blur"]
    local old_shader = LG.getShader()
    local r, g, b, a = LG.getColor()

    LG.push()
    LG.origin()
    if shader then
        if shader:hasUniform("texel_size") then shader:send("texel_size", { 1 / canvas:getWidth(), 1 / canvas:getHeight() }) end
        if shader:hasUniform("blur_radius") then shader:send("blur_radius", bg.blur_radius or 3.0) end
        if shader:hasUniform("dim_color") then shader:send("dim_color", bg.dim_color or { ck[1], ck[2], ck[3], 0.24 }) end
        if shader:hasUniform("time") then shader:send("time", bg.shader_time or (self._T.real_s) or 0) end
        LG.setShader(shader)
    end
    LG.setColor(cw)
    LG.draw(canvas, 0, 0)
    LG.setShader(old_shader)
    LG.pop()
    LG.setColor(r, g, b, a)
    return Y
end

end
