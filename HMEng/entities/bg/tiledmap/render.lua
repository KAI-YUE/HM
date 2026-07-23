local C, Render   = require("HMfns.animate.color.color_const"), require("HMfns.systems.render")
local ShaderUtils = require("HMEng.visual.shader_utils")
local DebugFlags  = require("HMGmgr.data.global.flags.debug_flags")
local LG          = love.graphics

local enqueue_drawable   = Render.enqueue_drawable
local push_draw_trans    = Render.push_actor_draw_transform
local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_sp_uniform    = ShaderUtils.send_sp_uniform

local cw    = C.WHITE

local Y, N  = true, false

return function (TiledMap)
--------------------------------------------------
--- draw
--------------------------------------------------
--- Helper: tile key | tile color
local function _tile_key(tile)         if type(tile) == "table" then return tile.key end; return tile end
local function _tile_color(tile)       return type(tile) == "table" and tile.color end
local function _tile_shader_key(tile)  if type(tile) == "table" then return tile.shader end end
local function _tile_shader_opts(tile) if type(tile) == "table" then return tile.shader_opts end end
local function _tile_rot(tile)         return type(tile) == "table" and tile.rot or 0 end
local function _tile_scale(tile)       if type(tile) ~= "table" then return 1, 1 end; return tile.sx or 1, tile.sy or 1 end

--- Helper: resolve quad
local function _resolve_quad(self, key)
    if not self.atlas or not key or self.missing_keys[key] then return end
    local ok, quad = pcall(self.atlas.get_quad, self.atlas, key); if ok then return quad end
    self.missing_keys[key] = Y
end

--- Helper: shader uniforms
local function _opt_val(tile_opts, map_opts, key, fallback)
    if tile_opts and tile_opts[key] then return tile_opts[key] end
    if map_opts and map_opts[key]   then return map_opts[key] end
    return fallback
end

--- Helper: send custom
local function _send_custom(shader, ...)
    for i = 1, select("#", ...) do
        local sends = select(i, ...)
        if not sends then goto continue end 
        for _, v in ipairs(sends) do if v.name then send_sp_uniform(shader, v.name, v.val) end end
        ::continue::
    end
end

--- Helper: apply tile shader
local function _apply_tile_shader(self, tile, quad)
    local shader_key  = _tile_shader_key(tile) or self.tile_shader
    local shader      = shader_key and self.t_shaders[shader_key];  if not shader then return end

    local qx, qy, qw, qh = quad:getViewport()
    local rw,     rh     = LG.getDimensions()
    local gm,     cam    = self.gm, self.gm.camera
    local cfg,    rcfg   = self.config or {}, gm.rcfg or {}
    local norm,   zoom   = rcfg.tile_scale*rcfg.tile_size, cam.zoom
    
    local world_phase_scale   = cfg.fblend_world_phase_scale or 0.18
    local tile_opts, map_opts = _tile_shader_opts(tile), self.tile_shader_opts
    
    send_base_uniforms(shader, {
        time = (self.gm._T and self.gm._T.shaders_s) or 0,
        tex_details = { qx, qy, qw, qh },
        image_details = self.atlas_dims or { self.atlas.image:getDimensions() },
    })
    send_sp_uniform(shader, "_tex_details",  { qx, qy, qw, qh })
    send_sp_uniform(shader, "image_details", self.atlas_dims or { self.atlas.image:getDimensions() })
    send_sp_uniform(shader, "resolution",    { rw, rh })
    send_sp_uniform(shader, "time",          (self.gm._T and self.gm._T.shaders_s) or 0)
    send_sp_uniform(shader, "vfield",        { 0, (self.gm._T and self.gm._T.shaders_s) or 0, self.ID or 0 })
    send_sp_uniform(shader, "hovering",      0)
    send_sp_uniform(shader, "fx_mask",       0)
    send_sp_uniform(shader, "edge_pad",      _opt_val(tile_opts, map_opts, "edge_pad", 1))
    send_sp_uniform(shader, "world_phase",   {
        world_phase_scale * ((cam and cam.x) or 0) * norm * zoom / math.max(rw, 1),
        world_phase_scale * ((cam and cam.y) or 0) * norm * zoom / math.max(rh, 1),
    })
    _send_custom(shader, map_opts and map_opts.send, tile_opts and tile_opts.send)
    return shader
end

--- Helper: _prepare_shared_tile_shader
local function _prepare_shared_tile_shader(self)
    local cfg = self.config or {};          if not cfg.tile_shader_uniforms_once then return end
    for r = 1, self.n_rows do
        local row = self.tiles[r]
        if not row then goto continue end 
        for c = 1, self.n_cols do
            local tile   = row[c]
            local key    = _tile_key(tile)
            local quad   = key and _resolve_quad(self, key)
            local shader = quad and _apply_tile_shader(self, tile, quad)
            if shader then return shader end
        end
        ::continue::
    end
end

--- Helper: draw tile
local function _draw_tile(self, tile, r_idx, c_idx, old_shader, shared_shader)
    local key = _tile_key(tile);           if not key then return end
    local quad = _resolve_quad(self, key); if not quad then return end

    local x,      y       = self:tile_to_local(r_idx, c_idx)
    local _, _,   qw, qh  = quad:getViewport()
    local tint,   shader  = _tile_color(tile) or cw, shared_shader or _apply_tile_shader(self, tile, quad)
    local rot,    sx, sy  = _tile_rot(tile), _tile_scale(tile)
    local overdraw        = (self.config and self.config.tile_overdraw) or 0.02
    local draw_w, draw_h  = self.tile_w + 2*overdraw, self.tile_h + 2*overdraw

    LG.setColor(tint)
    if shader and not shared_shader then LG.setShader(shader) end
    LG.draw(self.atlas.image, quad, x + 0.5*self.tile_w, y + 0.5*self.tile_h, rot, (draw_w/qw)*sx, (draw_h/qh)*sy, 0.5*qw, 0.5*qh)
    if shader and not shared_shader then LG.setShader(old_shader) end
end

---________________________________
--- main: draw
---________________________________
function TiledMap:draw()
    local st = self.states;                         if not st.visible then return end
    self:bound_me();                                enqueue_drawable(self.t_drawable, self)
    if DebugFlags.fps.skip_tiled_map_render then return end
    if not self.atlas then return end;              push_draw_trans(self)

    local old_shader    = LG.getShader()
    local shared_shader = _prepare_shared_tile_shader(self)
    if shared_shader then LG.setShader(shared_shader) end
    for r = 1, self.n_rows do
        local row = self.tiles[r]; if not row then goto continue end
        for c = 1, self.n_cols do _draw_tile(self, row[c], r, c, old_shader, shared_shader) end
        ::continue::
    end
    LG.setShader(old_shader)
    LG.pop()
    LG.setColor(cw)

    for _, child in pairs(self.children) do child:draw() end
end

end
