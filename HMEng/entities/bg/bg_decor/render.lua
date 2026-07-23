local Render, C   = require("HMfns.systems.render"), require("HMfns.animate.color.color_const")
local ShaderUtils = require("HMEng.visual.shader_utils")
local CUtils      = require("HMfns.animate.color.color_utils")
local LG          = love.graphics

local enqueue_drawable    = Render.enqueue_drawable
local push_draw_trans     = Render.push_actor_draw_transform
local send_base_uniforms  = ShaderUtils.send_base_uniforms
local send_sp_uniform     = ShaderUtils.send_sp_uniform
local tint_with_alpha     = CUtils.tint_with_alpha

local cw    = C.WHITE
local Y, N  = true, false

return function (BgDecor)
--------------------------------------------------
--- draw
--------------------------------------------------
--- Helper: resolve quad
local function _resolve_quad(self, key)
    if not self.atlas or not key or self.missing_keys[key] then return end
    local ok, quad = pcall(self.atlas.get_quad, self.atlas, key);  if ok then return quad end
    self.missing_keys[key] = Y
end

--- Helper: apply entry shader
local function _apply_entry_shader(self, entry, quad)
    local shader_key  = entry.shader
    local shader      = shader_key and self.t_shaders[shader_key];  if not shader then return end

    local qx, qy, qw, qh  = quad:getViewport()
    local rw,     rh      = LG.getDimensions()
    local gm,     img     = self.gm, self.atlas_dims
    local shader_time     = gm._T.shaders_s

    send_base_uniforms(shader, {  hovering = 0,  hover_tilt = 0,            screen_scale = 1,
        position_shader_mode = 0, fx_mask  = 0,  time       = shader_time,  tex_details  = { qx, qy, qw, qh },
        image_details = img,      shadow   = N })

    send_sp_uniform(shader, "resolution", { rw, rh })
    send_sp_uniform(shader, "speed", entry.speed or self.config.speed or 1)
    send_sp_uniform(shader, shader_key, { 0, shader_time, self.ID or 0 })
    return shader
end

--- Helper: compute entry alpha from group state
local function _entry_alpha(self, entry)
    if entry.visible == N     then return 0 end
    
    local draw_alpha = self.draw_alpha or 1
    if draw_alpha <= 0.001    then return 0 end
    if not self.group_states  then return draw_alpha end
    return draw_alpha*self:get_group_alpha(entry.group_idx or 1)
end

--- Helper: draw entry 
local function _draw_entry(self, entry, old_shader)
    local alpha = _entry_alpha(self, entry);  if alpha <= 0.001 then return end
    local key   = entry["key"]
    local quad  = _resolve_quad(self, key);   if not quad then return end

    local _, _, qw, qh = quad:getViewport()
    local eh,   ew     = entry["h"], entry["w"]
    
    if eh and not ew then ew = eh*(qw/qh) end
    if ew and not eh then eh = ew*(qh/qw) end

    local x,   y     = entry["x"]   or 0,  entry["y"]
    local rot, tint  = entry["rot"] or 0,  entry["color"] or cw
    local sx,  sy    = entry["sx"]  or 1,  entry["sy"] or 1
    local anchor     = entry["anchor"]
    local ox,  oy    = entry["ox"] or (anchor == "bottom" and 0.5*qw or 0.5*qw), entry["oy"] or (anchor == "bottom" and qh or 0.5*qh)
    local w,   h     = ew or self.tile_w or (eh and eh*(qw/qh)) or qw,           eh or self.tile_h or (ew and ew*(qh/qw)) or qh
    local shader     = _apply_entry_shader(self, entry, quad)

    LG.setColor(tint_with_alpha(tint, alpha))
    if shader then LG.setShader(shader) end
    LG.draw(self.atlas.image, quad, x, y, rot, (w/qw)*sx, (h/qh)*sy, ox, oy)
    if shader then LG.setShader(old_shader) end
end

---________________________________
--- main: draw 
---________________________________
function BgDecor:draw()
    local st = self.states; if not st.visible then return end
    if not self.atlas then return end; push_draw_trans(self)

    local old_shader = LG.getShader()
    for _, entry in ipairs(self.entries or {}) do _draw_entry(self, entry, old_shader) end
    LG.setShader(old_shader)
    LG.pop()
end

end
