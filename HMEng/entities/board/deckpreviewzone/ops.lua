local Actor = require("HMEng.actors.actor")

local push = table.insert
local Y, N = true, false

return function (DeckPreviewZone)
--------------------------------------------------
--- preview card lifecycle
--------------------------------------------------
function DeckPreviewZone:add_card(card)
    push(self.cards, card)
    card:set_zone(self)
    card.states.drag.can, card.states.collide.can = N, Y
    card.states.hover.can, card.states.click.can = Y, N
    card.rank = #self.cards
    self:mark_card_layout_dirty()
end

function DeckPreviewZone:take_card(card)
    for idx = #self.cards, 1, -1 do
        if self.cards[idx] == card then
            table.remove(self.cards, idx)
            card:detach_from_zone()
            self:mark_card_layout_dirty()
            return card
        end
    end
end

--------------------------------------------------
--- movement and removal
--------------------------------------------------
function DeckPreviewZone:move(dt) Actor.move(self, dt); self:flush_card_layout() end

function DeckPreviewZone:hard_set_T(x, y, w, h)
    local T = self.T
    Actor.hard_set_T(self, x or T.x, y or T.y, w or T.w, h or T.h)
    self:align_cards()
    self.card_layout_dirty = N
end

function DeckPreviewZone:remove()
    for idx = #self.cards, 1, -1 do self:take_card(self.cards[idx]) end
    DeckPreviewZone.super.remove(self)
end
end
