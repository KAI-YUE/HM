
local class = require("core.class")
local Deck  = class:extend()

local function install(mod) mod(Deck) end
local install_list = {"registry", "gameplay", "ops", "render"}
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.deck." .. pkg)) end

-------------------------------------------------------
-- Deck: init & methods 
-------------------------------------------------------
function Deck:init(gm, back) self:init_back_attributes(gm, back) end
function Deck:get_name() if self.effect.template.unlocked then return self.loc_name else return self.locked_name end end

return Deck
