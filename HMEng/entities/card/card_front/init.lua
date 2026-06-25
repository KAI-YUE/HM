local Actor  = require("HMEng.actors.actor")
local layout = require("HMEng.entities.card.card_front.build_face.basic_layout")

local CardFront = Actor:extend()

local function install(mod) mod(CardFront) end
local install_list = { "registry" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.card.card_front." .. pkg)) end

local install_face = { "face_debug", "face_pips", "face_corners", "cardface", "render" }
for _, pkg in ipairs(install_face) do install(require("HMEng.entities.card.card_front.build_face." .. pkg)) end

--------------------------------------------------
--- CardFront: init & methods 
--------------------------------------------------
function CardFront:init(gm, x, y, w, h, card, params) self:init_front_attributes(gm, x, y, w, h, card, params) end 
function CardFront:set_card(card) self.card, self._dirty = card, true end

return CardFront
