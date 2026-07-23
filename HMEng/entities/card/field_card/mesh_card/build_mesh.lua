local TabUtils  = require("HMfns.utils.table_utils")

local deep_copy = TabUtils.deep_copy
local rand = math.random

local Y, N = true, false

return function (MeshCard)
---------------------------------------------
--- Sync projection when only pose/quad changes
---------------------------------------------
--- Helper: uv from spritor 
local function _uv_from_spritor(sp)
    if not sp or not sp.quad_viewport or not sp.image_dims then return end
    local qv, dims = sp:quad_viewport(), sp:image_dims()
    local iw, ih = dims[1], dims[2]
    if not iw or not ih or iw == 0 or ih == 0 then return end
    local uv = { u1 = qv[1] / iw, v1 = qv[2] / ih, u2 = (qv[1] + qv[3]) / iw, v2 = (qv[2] + qv[4]) / ih }
    return uv
end

--- Helper: update mesh art 
local function _update_mesh_part(self, key)
    local card, projector, quad = self.card, self.projector, self.projected_quad
    if not card or not projector or not quad then return end

    local ch, meshes  = card.children, self.meshes
    local sp, mesh    = ch[key], meshes[key]
    if not sp or not sp.img or not mesh then return end
    if sp.face_dirty and sp._rebuild_face_canvas then sp:_rebuild_face_canvas() end

    local uv = _uv_from_spritor(sp)
    if not uv then return end
    projector:apply_to_mesh(mesh, quad, uv)
end

---______________________________________
--- main: sync projection 
---______________________________________
function MeshCard:sync_projection(quad)
    local card = self.card
    if not card or not quad then return end

    self.T, self.VT = deep_copy(card.T), deep_copy(card.VT)
    self.projector      = card.zone and card.zone.projector 
    self.projected_quad = quad

    if not next(self.meshes) then self.needs_mesh_sync = Y; return; end

    _update_mesh_part(self, "template")
    _update_mesh_part(self, "front")
    _update_mesh_part(self, "back")
    self.needs_mesh_sync = N
end


---------------------------------------------
--- Build mesh part
---------------------------------------------
function MeshCard:build_mesh_part(key)
    local card, projector, quad = self.card, self.projector, self.projected_quad
    if not card or not projector or not quad then return end

    local ch, meshes = card.children, self.meshes
    local sp = ch[key]
    if not sp or not sp.img then return end
    if sp.face_dirty and sp._rebuild_face_canvas then sp:_rebuild_face_canvas() end

    local uv, tex = _uv_from_spritor(sp), sp.img
    if not tex or not uv then return end

    meshes[key] = projector:new_card_mesh(tex)
    projector:apply_to_mesh(meshes[key], quad, uv)
end

---------------------------------------------
--- Build meshes
---------------------------------------------
function MeshCard:build_meshes()
    local card, projector, quad = self.card, self.projector, self.projected_quad
    if not card or not projector or not quad then return end

    self:build_mesh_part("template")
    self:build_mesh_part("front")
    self:build_mesh_part("back")

    self.needs_mesh_sync = N
end

---------------------------------------------
--- Sync from card
---------------------------------------------
function MeshCard:sync_from_card()
    local card = self.card

    self.T, self.VT = deep_copy(card.T), deep_copy(card.VT)
    self.projector = card.zone and card.zone.projector 
    self.needs_mesh_sync = Y
end

end
