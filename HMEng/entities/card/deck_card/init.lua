local FieldCard = require("HMEng.entities.card.field_card")
local DeckCard  = FieldCard:extend()

local function install(mod) mod(DeckCard) end
local install_list = { "misc" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.card.deck_card.utils." .. pkg)) end

-----------------------------------------
--- init
-----------------------------------------
function DeckCard:init(gm, x, y, w, h, card, center, params) DeckCard.super.init(self, gm, x, y, w, h, card, center, params) end

return DeckCard
