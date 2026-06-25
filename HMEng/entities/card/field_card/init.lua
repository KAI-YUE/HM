local Card      = require("HMEng.entities.card")
local FieldCard = Card:extend()

local function install(mod) mod(FieldCard) end
local install_list = { "cardzone", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.card.field_card." .. pkg)) end

local utils_list = { "misc", "ops" }
for _, pkg in ipairs(utils_list) do install(require("HMEng.entities.card.field_card.utils." .. pkg)) end

-----------------------------------------
--- init 
-----------------------------------------
function FieldCard:init(gm, x, y, w, h, card, center, params) FieldCard.super.init(self, gm, x, y, w, h, card, center, params) end

return FieldCard
