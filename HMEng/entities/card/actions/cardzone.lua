local Y, N = true, false

return function (Card)
--------------------------------------------
--- set zone
--------------------------------------------
--- Helper: is_projected_zone | set based zone | set_shadow_enabled | disable_shadow | enable shadow
local function _is_projected_zone(zone)    return zone and zone.projector end
function Card:_set_base_zone(zone)
    self.zone, self.parent = zone, zone; self.layered_parallax = zone and zone.layered_parallax
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(self) end
end
function Card:set_shadow_enabled(enabled)  local st = self.states and self.states.hide_shadow; if st then st.is = (not enabled) end; return self end
function Card:disable_shadow()             return self:set_shadow_enabled(N) end
function Card:enable_shadow()              return self:set_shadow_enabled(Y) end

--- Helper: demote | promote to field_card | promote to deck_card
function Card:demote_to_card() if getmetatable(self) ~= Card then setmetatable(self, Card) end; return self end
function Card:promote_to_field_card() local FieldCard = require("HMEng.entities.card.field_card"); if getmetatable(self) ~= FieldCard then setmetatable(self, FieldCard) end; return self end
function Card:promote_to_deck_card()  local DeckCard  = require("HMEng.entities.card.deck_card");  if getmetatable(self) ~= DeckCard  then setmetatable(self, DeckCard)  end; return self end

---_____________________________
--- main: set zone 
---_____________________________
function Card:set_zone(zone)
    if zone and zone.is_deck and zone:is_deck() then return self:promote_to_deck_card():set_zone(zone) end
    if _is_projected_zone(zone) then return self:promote_to_field_card():set_zone(zone) end
    self:_set_base_zone(zone)
end

---------------------------------------------
--- detach from card_zone
---------------------------------------------
function Card:detach_from_zone()
    self.zone, self.parent, self.layered_parallax = nil, nil, { x = 0, y = 0 }
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(self) end
end
function Card:remove_from_zone() self:detach_from_zone() end

-------------------------------------------------------------
--- MISC parent fns 
-------------------------------------------------------------
function Card:assign_field_quad(quad)   return quad end
function Card:get_projected_quad()      return end
function Card:sync_field_presentation() end
function Card:is_field_card()           return N end
function Card:is_deck_card()            return N end

end
