local LG = love.graphics

local Y, N = true, false

return function (CardFront)
--------------------------------------------
--- init face cache 
-------------------------------------------
function CardFront:_init_face_cache()
    if self.face_canvas and not self.face_dirty then return end 
	self.face_px_w,  self.face_px_h    = self.face_px_w or 138, self.face_px_h or 200
	self.face_dirty, self.face_canvas  = Y, self.face_canvas or LG.newCanvas(self.face_px_w, self.face_px_h)
    self.fw,         self.fh           = self.face_canvas:getDimensions()
    
    self.img  = self.face_canvas       -- dummy image 
end

--- Helper: render face frame
function CardFront:_render_face_frame(cw, ch)
    local q = self.frame_quad;                  if not q then return end
    local _, _, fw, fh = q:getViewport()
    LG.draw(self.frame_img, q, 0, 0, 0, cw/fw, ch/fh)
end

-- Helper: Draw the face content into the cache (ONE TIME when dirty)
function CardFront:_rebuild_face_canvas()
	self:_init_face_cache()
    self:refresh_debug_field_coords()

	local old_canvas, old_shader = LG.getCanvas(), LG.getShader()

    LG.push();                      LG.setCanvas(self.face_canvas)
	LG.setShader();                 LG.clear(0, 0, 0, 0)
	LG.origin();                	LG.setColor(1, 1, 1, 1)

    -- Draw in canvas-local pixel space
	local cw, ch = self.face_px_w, self.face_px_h

    self:_render_face_frame(cw, ch)
    if self.face_style ~= "pip" then self:_render_custom_face(cw, ch)
    else self:_render_pip_face(cw, ch) end

    self:_render_rank(cw, ch)
	self:_render_cor_suit(cw, ch)
    self:draw_debug_field_coords(cw, ch)

	LG.setColor(1, 1, 1, 1)
    LG.pop()
	LG.setShader(old_shader)
	if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end

	self.face_dirty = N
end

-- Helper: draw the cached face as ONE texture
function CardFront:_render()
    self:refresh_debug_field_coords()
	if self.face_dirty then self:_rebuild_face_canvas() end

	local VT     = self.VT
	local cw, ch = VT.w, VT.h
	local fw, fh = self.face_canvas:getWidth(), self.face_canvas:getHeight()
	LG.setColor(1, 1, 1, 1)
	LG.draw(self.face_canvas, 0, 0, 0, cw/fw, ch/fh)
end

end 
