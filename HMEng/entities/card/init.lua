local Actor = require("HMEng.actors.actor")
local Card  = Actor:extend()

local function install(mod) mod(Card) end
local install_list = { "registry" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.card." .. pkg)) end

local install_actions = { "align", "cardzone", "move", "ops", "update" }
for _, pkg in ipairs(install_actions) do install(require("HMEng.entities.card.actions." .. pkg)) end

local install_factory = { "edition", "joint_canvas", "render", "set_values", "shatter", "suit_rank" }
for _, pkg in ipairs(install_factory) do install(require("HMEng.entities.card.in_factory." .. pkg)) end

local install_utils = { "get_values", "parallax",  "save_load" }
for _, pkg in ipairs(install_utils) do install(require("HMEng.entities.card.utils." .. pkg)) end

local install_inter = { "usr_inter", "buy_sell" }
for _, pkg in ipairs(install_inter) do install(require("HMEng.entities.card.interactions." .. pkg)) end

-------------------------------------------------------
-- Card: init & methods 
-------------------------------------------------------
function Card:init(gm, x, y, w, h, card, center, params) self:init_card_attributes(gm, x, y, w, h, card, center, params) end
function Card:get_seal(bypass_debuff) if self.debuff and not bypass_debuff then return end; return self.seal end
function Card:build_front_canvas() self.children.front:_rebuild_face_canvas() end

return Card
