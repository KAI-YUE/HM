local C, LG      = require("HMfns.animate.color.color_const"), love.graphics
local Lens       = require("core.transform.lens")
local Render     = require("HMfns.systems.render")
local ShaderUtils = require("HMEng.visual.shader_utils")

local abs = math.abs
local push_draw_trans  = Render.push_actor_draw_transform

local cw = C.WHITE
local Y, N = true, false

return function (MeshCard)
--------------------------------------------
--- Handle shader
--------------------------------------------
--- Helpers: shader visible & mesh_dim
local function _shader_visible(st)      return (not st.shader_visible) or st.shader_visible.is end
local function _suit_shader_visible(st) return (not st.suit_shader_visible) or st.suit_shader_visible.is end
local function _mesh_dims(mesh)         local tex = mesh and mesh:getTexture(); if not tex then return { 0, 0 } else return { tex:getWidth(), tex:getHeight() } end  end

---_______________________________
--- main: handle shader 
---_______________________________
function MeshCard:handle_shader(h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major, target)
    local card = self.card;     if not card then return end

    local sts     = card.states
    local ht_dt   = sts.hover.is or sts.drag.is
    local source  = target and target.source
    local SS      = self.t_shaders and self.t_shaders[_shader]
    
    ShaderUtils.handle_shader(self, {
        hovering                  = ht_dt and 1 or 0,
        zero_hover_tilt_when_idle = Y,
        tex_details               = function() return (source:quad_viewport()) or { 0, 0, 1, 1 } end,
        image_details             = function() return (source:image_dims()) or _mesh_dims(target and target.mesh) end,
    }, h, _send, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)

    if not SS then return end
    if SS:hasUniform("position_shader_mode") then SS:send("position_shader_mode", 1) end
    if _send then SS:send(_shader, _send) end
end

--------------------------------------------
--- Draw shader
--------------------------------------------
--- Helper: active target
local function _active_targets(self, is_shadow)
    local card, meshes = self.card, self.meshes;    if not card then return {} end
    local ch = card.children

    if is_shadow then return { { key = "template", mesh = meshes.template, source = ch.template, type = "shadow" } } end
    if card.sprite_facing == "front" then
        return {
            { key = "template", mesh = meshes.template, source = ch.template, type = "front" },
            { key = "front",    mesh = meshes.front,    source = ch.front,    type = "front" },
        }
    end
    
    return { { key = "back", mesh = meshes.back, source = ch.back, type = "back" } }
end

--- Helper: target shader key
local function _target_shader_key(self, target)
    local card, source = self.card, target and target.source
    if not card or not target then return "generic" end

    if target.key == "template" then return card.template_shader or "generic" end
    if target.key == "front"    then
        if not _suit_shader_visible(card.states) then return card.template_shader or "generic" end
        return (source and source.suit_shader) or card.template_shader or "generic"
    end
    if target.key == "back"     then return "generic" end
end

--- Helper: draw color 
local function _draw_color(self, overlay)
    local color, card = overlay or cw, self.card
    local alpha = card and card.draw_alpha
    local zone  = card and card.zone
    if zone and zone.is_deck and zone:is_deck() then alpha = (alpha or 1) * (zone.draw_alpha or 1) end
    if alpha == nil then return color end
    return { color[1], color[2], color[3], (color[4] or 1)*alpha }
end

--- Helper: refresh card face canvas state before using it as a mesh texture
local function _refresh_face_sources(self)
    local front = self.card and self.card.children and self.card.children.front
    if front and front.refresh_debug_field_coords then front:refresh_debug_field_coords() end
    if front and front.face_dirty and front._rebuild_face_canvas then front:_rebuild_face_canvas() end
end

--- Helper: draw meshes 
local function _draw_meshes(self, overlay)
    _refresh_face_sources(self)
    push_draw_trans(self)
    LG.setColor(_draw_color(self, overlay))
    for _, target in ipairs(_active_targets(self)) do if target.mesh then LG.draw(target.mesh) end end
    LG.pop()
    LG.setColor(cw)
end

---________________________________
--- main: draw shader
---________________________________
function MeshCard:draw_shader(_shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow, overlay)
    return ShaderUtils.draw_shader(self, {
        skip_handle_shader = Y,
        get_draw_major = function(obj) return obj.card and (obj.card.role.draw_major or obj.card) end,
        prepare = function(obj, ctx)
            _refresh_face_sources(obj)
            if obj.needs_mesh_sync then obj:build_meshes() end
            if not obj.states.visible or not obj.projected_quad or not obj.card then return N end
            if not _shader_visible(obj.card.states) then ctx.result = _draw_meshes(obj, overlay); return N end

            ctx.is_shadow = not not ctx.h
        end,
        draw_with_shader = function(obj, ctx)
            push_draw_trans(obj)
            LG.setColor(_draw_color(obj, overlay))
            for _, target in ipairs(_active_targets(obj, ctx.is_shadow)) do
                if not target.mesh then goto continue end 
                obj:handle_shader(ctx.h, ctx.send, ctx.no_tilt, ctx.shader, ctx.custom_shader, ctx.tilt_shadow, ctx.draw_major, target)
                LG.draw(target.mesh)
                ::continue::
            end
            LG.pop()
            LG.setColor(cw)
        end,
    }, _shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
end

--------------------------------------------
--- Draw
--------------------------------------------
function MeshCard:draw(overlay)
    _refresh_face_sources(self)
    if self.needs_mesh_sync then self:build_meshes() end
    if not self.states.visible or not self.projected_quad then return end
    if not self.card then return end
    if not _shader_visible(self.card.states) then return _draw_meshes(self, overlay) end

    local S, card = self.card.gm.t_shaders, self.card
    local args    = card.args or {}
    local send    = args.send2fs
    local draw_major = card.role.draw_major or card

    push_draw_trans(self)
    LG.setColor(_draw_color(self, overlay))
    
    for _, target in ipairs(_active_targets(self)) do
        local mesh = target.mesh
        local shader_key = _target_shader_key(self, target)
        local shader = S[shader_key]
        if not mesh or not shader then goto continue end

        self:handle_shader(nil, send, nil, shader_key, nil, nil, draw_major, target)
        if shader:hasUniform("position_shader_mode") then shader:send("position_shader_mode", 1) end
        LG.setShader(shader)
        LG.draw(mesh)
        LG.setShader()
        ::continue::
    end
    LG.pop()
    LG.setColor(cw)
end

--------------------------------------------
--- Draw shadow
--------------------------------------------
function MeshCard:draw_shadow(_shader, h) return self:draw_shader(_shader, h, nil, nil, nil, nil, nil, nil, nil, nil, self.card and self.card.tilt_shadow) end

end
