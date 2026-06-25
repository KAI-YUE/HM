local MeshCard = require("HMEng.entities.card.field_card.mesh_card")

return function (FieldCard)
local Y, N = true, false

------------------------------------------------
--- board path interaction click
------------------------------------------------
function FieldCard:click()
    local zone = self.zone
    local board = zone and zone.boardzone
    if board and board.handle_path_cell_click and board:handle_path_cell_click(self.cell) then return Y end
    if board and board.handle_bridge_cell_click and board:handle_bridge_cell_click(self.cell) then return Y end
    return FieldCard.super.click(self)
end

------------------------------------------------
--- set zone 
------------------------------------------------
--- Helper: ensure mesh card 
local function _ensure_mesh_card(self)
    local ch = self.children; if not ch then return end
    ch.mesh_card = ch.mesh_card or MeshCard(self)
    ch.mesh_card:sync_from_card()
    return ch.mesh_card
end

---_________________________________
--- main: set zone 
---_________________________________
function FieldCard:set_zone(zone)
    self:_set_base_zone(zone)
    -- if zone == self.gm.deck then self:disable_shadow() else self:enable_shadow() end
    if not (zone and zone.projector) then return end
    _ensure_mesh_card(self)
end

-----------------------------------------------
--- assign_field_quad
-----------------------------------------------
function FieldCard:assign_field_quad(quad)
    local mesh_card = _ensure_mesh_card(self); if not mesh_card then return end
    mesh_card:sync_projection(quad)
    return quad
end

-----------------------------------------------
--- misc child fns 
-----------------------------------------------
function FieldCard:get_projected_quad()       local mesh_card = self.children and self.children.mesh_card; return mesh_card and mesh_card.projected_quad  end
function FieldCard:sync_field_presentation()  local mesh_card = self.children.mesh_card; if mesh_card then mesh_card:sync_from_card() end end
function FieldCard:is_field_card()            return Y end

------------------------------------------------
--- detach from zone 
------------------------------------------------
--- Helper: clear mesh card
local function _clear_mesh_card(self)
    local mesh_card = self.children and self.children.mesh_card; if not mesh_card then return end
    mesh_card.projector, mesh_card.projected_quad, mesh_card.needs_mesh_sync = nil, nil, Y
end

---_________________________________
--- main: detach from zone 
---_________________________________
function FieldCard:detach_from_zone()
    self:clear_cell()
    self:enable_shadow()
    FieldCard.super.detach_from_zone(self)
    _clear_mesh_card(self)
    self:demote_to_card()
end

------------------------------------------------
--- remove from zone 
------------------------------------------------
function FieldCard:remove_from_zone()
    self:detach_from_zone()

    local mesh_card = self.children and self.children.mesh_card
    if not mesh_card then return end
    mesh_card:remove()
    self.children.mesh_card = nil
end

end
