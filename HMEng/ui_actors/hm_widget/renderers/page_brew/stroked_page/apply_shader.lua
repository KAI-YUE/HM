local ShaderUtils = require("HMEng.visual.shader_utils")
local LG          = love.graphics

local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_sp_uniform    = ShaderUtils.send_sp_uniform
local min, max           = math.min, math.max

local Y, N = true, false

local M = {}

-----------------------------
--- apply_seam_shader
----------------------------------
--- Helper: _mask_domain
local function _mask_domain(self, wpx, hpx)
    local cfg, _room  = self.config, self.gm._room
    local x, y, w, h  = 0, 0, wpx, hpx

    if cfg.fx_mask_ref == "room" and _room.T then
        local VT, RT, tz = self.VT, self.gm._room.T, self.rcfg.tile_size
        x, y, w, h = (RT.x - VT.x)*tz, (RT.y - VT.y)*tz, RT.w*tz, 0.67*RT.h*tz
    end

    local x0, y0 = LG.transformPoint(x,     y)
    local x1, y1 = LG.transformPoint(x + w, y)
    local x2, y2 = LG.transformPoint(x,     y + h)
    local x3, y3 = LG.transformPoint(x + w, y + h)

    local sx0, sy0 = min(x0, x1, x2, x3), min(y0, y1, y2, y3)
    local sx1, sy1 = max(x0, x1, x2, x3), max(y0, y1, y2, y3)

    return { 0, 0, w, h }, { w, h }, { sx0, sy0, max(sx1 - sx0, 1), max(sy1 - sy0, 1) }
end

---____________________________
--- main: apply_seam_shader
---______________________________________
function M.apply_seam_shader(self, region, px, py, r, wpx, hpx)
    local cfg = self.config
    local shader_name = cfg.seam_shader;        if not shader_name then return end
    local shader = self.gm.t_shaders and self.gm.t_shaders[shader_name];        if not shader then return end

    local nx, ny = -math.sin(r), math.cos(r)
    local sx0, sy0 = LG.transformPoint(px, py)
    local sx1, sy1 = LG.transformPoint(px + nx, py + ny)
    nx, ny = sx1 - sx0, sy1 - sy0

    local len = (nx*nx + ny*ny)^0.5
    if len <= 0.0001 then return end

    local old_shader = LG.getShader()
    local now = self.gm._T.real_s or 0
    local fx_mask = self.fx_mask or 0

    send_base_uniforms(shader, { fx_mask = fx_mask, time = now, shadow = N })

    if fx_mask > 0.001 then
        local tex_details, image_details, wipe_rect = _mask_domain(self, wpx, hpx)
        send_base_uniforms(shader, {
            fx_mask       = fx_mask,
            time          = now,
            tex_details   = tex_details,
            image_details = image_details,
            shadow        = N,
        })
        send_sp_uniform(shader, "fx_mask_dir", self.fx_mask_dir or cfg.fx_mask_dir or 0)
        send_sp_uniform(shader, "fx_mask_seed", self.fx_mask_seed or cfg.fx_mask_seed or 0)
        send_sp_uniform(shader, "wipe_rect", wipe_rect)
        send_sp_uniform(shader, "generic",   { 0, now, self.ID or 0 })
    end

    send_sp_uniform(shader, "seam_point",  { sx0, sy0 })
    send_sp_uniform(shader, "seam_normal", { nx/len, ny/len })
    send_sp_uniform(shader, "seam_side",   region.side or 1)
    send_sp_uniform(shader, "feather_px",  cfg.seam_feather or 5)
    LG.setShader(shader)
    return Y, old_shader
end

-----------------------------
--- apply_polygon_shader
----------------------------------
--- Helper: _polygon_packed_points
local function _polygon_packed_points(points)
    local packed = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } }
    local count = math.min(math.floor(#points/2), 8)
    for i = 1, count do
        local sx, sy = LG.transformPoint(points[2*i - 1], points[2*i])
        local pack = packed[math.floor((i - 1)/2) + 1]
        local offset = ((i - 1)%2)*2
        pack[offset + 1], pack[offset + 2] = sx, sy
    end
    return packed, count
end

---____________________________
--- main: apply_polygon_shader
---______________________________________
function M.apply_polygon_shader(self, polygon, points, wpx, hpx)
    local gm,     cfg     = self.gm, self.config
    local paint           = polygon.paint or {}
    local shader_name     = paint.shader or polygon.shader;     if not shader_name then return end
    local shader          = gm.t_shaders[shader_name];          if not shader then return end
    local packed, count   = _polygon_packed_points(points);     if count < 3 then return end
    local old_shader      = LG.getShader()
    local now,    fx_mask = gm._T.real_s or 0, self.fx_mask or 0

    send_base_uniforms(shader, { fx_mask = fx_mask, time = now, shadow = N })

    if fx_mask > 0.001 then
        local tex_details, image_details, wipe_rect = _mask_domain(self, wpx, hpx)
        send_base_uniforms(shader, {
            fx_mask       = fx_mask,
            time          = now,
            tex_details   = tex_details,
            image_details = image_details,
            shadow        = N,
        })
        send_sp_uniform(shader, "fx_mask_dir", self.fx_mask_dir or cfg.fx_mask_dir or 0)
        send_sp_uniform(shader, "fx_mask_seed", self.fx_mask_seed or cfg.fx_mask_seed or 0)
        send_sp_uniform(shader, "wipe_rect", wipe_rect)
    end

    send_sp_uniform(shader, "generic",     { 0, now, self.ID or 0 })
    send_sp_uniform(shader, "poly_p01",    packed[1])
    send_sp_uniform(shader, "poly_p23",    packed[2])
    send_sp_uniform(shader, "poly_p45",    packed[3])
    send_sp_uniform(shader, "poly_p67",    packed[4])
    send_sp_uniform(shader, "point_count", count)
    send_sp_uniform(shader, "feather_px",  paint.feather_px or polygon.feather_px or self.config.polygon_feather or self.config.seam_feather or 5)
    LG.setShader(shader)
    return Y, old_shader
end

---____________________________
--- main: apply_fx_mask_shader
---______________________________________
function M.apply_fx_mask_shader(self, wpx, hpx)
    local gm,    cfg  = self.gm, self.config
    local shader_name = cfg.fx_mask_shader;         if not shader_name then return end
    local fx_mask     = self.fx_mask or 0;          if fx_mask <= 0.001 then return end
    local shader      = gm.t_shaders[shader_name];  if not shader then return end

    local tex_details, image_details, wipe_rect = _mask_domain(self, wpx, hpx)
    local now         = self._T.real_s or 0
    local old_shader  = LG.getShader()

    send_base_uniforms(shader, {
        fx_mask       = fx_mask,
        time          = now,
        tex_details   = tex_details,
        image_details = image_details,
        shadow        = N,
    })
    send_sp_uniform(shader, "fx_mask_dir",  self.fx_mask_dir or cfg.fx_mask_dir or 0)
    send_sp_uniform(shader, "fx_mask_seed", self.fx_mask_seed or cfg.fx_mask_seed or 0)
    send_sp_uniform(shader, "wipe_rect", wipe_rect)
    send_sp_uniform(shader, "generic",   { 0, now, self.ID or 0 })
    LG.setShader(shader)
    return Y, old_shader
end

function M.clear_shader(applied, old_shader) if applied then LG.setShader(old_shader) end end

return M
