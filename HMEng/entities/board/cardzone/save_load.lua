local TabUtils = require("HMfns.utils.table_utils")

local destroy_tree = TabUtils.destroy_tree
local push = table.insert

local Y, N = true, false

return function(CardZone)
---------------------------------------
--- Save 
---------------------------------------
function CardZone:save()
    if not self.cards then return end
    local cardarea_tab = { cards = {}, config = self.config }
    local ca_cards, cards = cardarea_tab.cards, self.cards
    for i = 1, #cards do push(ca_cards, cards[i]:save()) end
    if self.save_alignment_state then cardarea_tab.alignment = self:save_alignment_state() end
    return cardarea_tab
end

---------------------------------------
--- Load 
---------------------------------------
function CardZone:load(gm, cardarea_tab)
    if self.cards then destroy_tree(self.cards) end;        self.cards = {}
    if self.children then destroy_tree(self.children) end;  self.children = {}

    local Card     = require("HMEng.entities.card");        local gm = self.gm
    self.config    = cardarea_tab.config;                   local PC = gm.CMod
    local ca_cards = cardarea_tab.cards;                    local cards, _hl = self.cards, self.highlighted

    for i = 1, #ca_cards do
        local card = Card(gm, 0, 0, gm.card_w, gm.card_h, PC.j_joker, PC.c_base)
        card:load(gm, ca_cards[i]);                         push(cards, card)
        if card.highlighted then push(_hl, card) end
        card:set_zone(self)
    end
    self:set_zone_sts()
    if self.restore_alignment_state then self:restore_alignment_state(cardarea_tab.alignment) end
    self:align_cards()
    self:hard_set_cards()
end

end
