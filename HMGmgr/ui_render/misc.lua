local LG       = love.graphics

local Y, N = true, false
local RENDER_BUCKET_KEYS = { "GOBJ", "ACTOR", "TMAP", "BOARDZONE", "CARDZONE", "CHARA", "UIPANEL", "POPUP", "SHADERFX" }

return function(GMgr)
-----------------------------
--- world render helpers
----------------------------------
--- Helper: _push_world_camera
function GMgr:_push_world_camera()
    local cam = self.camera;                        if not cam or not cam.active then return N end
    local rcfg  = self.rcfg
    local norm  = rcfg.tile_scale * rcfg.tile_size
    local vp    = cam.viewport
    local zoom  = cam.zoom or 1
    LG.push()
    LG.translate((vp.x or 0)*norm, (vp.y or 0)*norm)
    LG.scale(zoom)
    LG.translate(-cam.x*norm, -cam.y*norm)
    return Y
end

--- Helper: _pop_world_camera | draw_bg
function GMgr:_pop_world_camera(applied) if applied then LG.pop() end end
local function draw_bg(bg) LG.push(); bg:translate_container(); bg:draw(); LG.pop() end

-----------------------------
--- render buckets
----------------------------
--- Helper: mark render buckets dirty
function GMgr:mark_render_buckets_dirty() self.render_buckets_dirty = Y end

--- Helper: refresh render buckets
function GMgr:_refresh_render_buckets()
    local R, buckets = self.R, self.render_buckets or {}
    for _, key in ipairs(RENDER_BUCKET_KEYS) do
        local src, out = R and R[key], buckets[key] or {}
        for i = #out, 1, -1 do out[i] = nil end
        for _, v in pairs(src or {}) do if v and not v.REMOVED then out[#out + 1] = v end end
        buckets[key] = out
    end
    self.render_buckets, self.render_buckets_dirty = buckets, N
end

--- Helper: render bucket
function GMgr:render_bucket(key)
    if self.render_buckets_dirty or not self.render_buckets then self:_refresh_render_buckets() end
    return self.render_buckets[key] or {}
end

--- Helper: _draw_world_field
function GMgr:_draw_world_field()
    local bg      = self.bg
    local applied = self:_push_world_camera()
    if bg then draw_bg(bg) end
    self:_pop_world_camera(applied)
end

--- Helper: _render_obj
function GMgr:_render_obj(v, skip_parent)
    if not v then return N end
    if skip_parent and v.parent then return N end
    LG.push(); v:translate_container(); v:draw(); LG.pop()
    return Y
end

--- Helper: is_field_world_obj
local function is_field_world_obj(v)
    if v and v.kind == "sky_decorator" then return Y end

    local cfg = v and v.config
    if cfg and cfg.type == "field_board" then return Y end
    if cfg and cfg.type == "field_dec" then return Y end
    if cfg and cfg.type == "field_decor" then return Y end

    local role  = v and v.role
    local major = role and role.major
    local mcfg  = major and major.config
    if mcfg and mcfg.type == "field_board" then return Y end

    local gridzone = v and v.gridzone
    local gcfg     = gridzone and gridzone.config
    if gcfg and gcfg.type == "field" then return Y end

    local zone = v and v.zone
    cfg = zone and zone.config
    return cfg and cfg.type == "field"
end

--- Helper: refresh render context
function GMgr:refresh_render_context(v)
    if not v then return N end
    v.render_in_world = is_field_world_obj(v) and Y or N
    v.render_context_cached = Y
    self:mark_render_buckets_dirty()
    return v.render_in_world
end

--- Helper: _render_obj_in_context
function GMgr:_render_obj_in_context(v, skip_parent)
    if not v then return N end
    local render_in_world = v.render_in_world
    if not v.render_context_cached then render_in_world = self:refresh_render_context(v) end
    if not render_in_world then return self:_render_obj(v, skip_parent) end

    local applied  = self:_push_world_camera()
    local rendered = self:_render_obj(v, skip_parent)
    self:_pop_world_camera(applied)
    return rendered
end

--- Helper: _render_shader_fx_pass
function GMgr:_render_shader_fx_pass(layer)
    local registry = self:render_bucket("SHADERFX"); if not registry then return end
    for _, v in pairs(registry) do if v and v.shader_fx_layer == layer then self:_render_obj_in_context(v) end end
end

--- Helper: _render_cursor
function GMgr:_render_cursor()
    local p_cursor, rcfg = self.p_cursor, self.rcfg
    local tz, ts, pT     = rcfg.tile_size, rcfg.tile_scale, p_cursor.T
    local norm           = tz*ts
    LG.push()
    p_cursor:translate_container()
    LG.translate(-pT.w*norm*0.5, -pT.h*norm*0.5)
    p_cursor:draw();                LG.pop()
end

end
