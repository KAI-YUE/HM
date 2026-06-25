local Actor = require("HMEng.actors.actor")

return function (FieldCard)
-------------------------------------------------------
--- set cell | clear cell
-------------------------------------------------------
function FieldCard:set_cell(r_idx, c_idx) self.cell = self.cell or {};    self.cell.row, self.cell.col = r_idx, c_idx end
function FieldCard:clear_cell() self:set_cell(nil, nil) end

---------------------------------------------
--- hit_test 
--------------------------------------------
--- Helper: set camera 
function FieldCard:_set_camera(cam, point)
    local args = self.args
    args.card_camera_point = args.card_camera_point or {}
    point = cam:screen_to_world_point(point, args.card_camera_point)
    return point
end

---____________________________________
--- main: hit_test
---____________________________________
function FieldCard:hit_test(point)
    local zone, gm  = self.zone, self.gm
    local cam       = gm.camera
    local is_field  = (zone and zone.config.type == "field")
    if cam and cam.active and is_field then point = self:_set_camera(cam, point) end

    local mesh_card = self.children and self.children.mesh_card
    if not mesh_card or not mesh_card:is_ready() then return Actor.hit_test(self, point) end

    local quad, projector = mesh_card.projected_quad, mesh_card.projector
    if not quad or not projector then return Actor.hit_test(self, point) end
    return projector:point_in_quad(projector:to_mesh_local(self, point), quad)
end

end
