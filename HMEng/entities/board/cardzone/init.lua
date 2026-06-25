local Actor    = require("HMEng.actors.actor")
local CardZone = Actor:extend()

local function install(mod) mod(CardZone) end
local install_list = { "registry", "ops", "align",  "highlight", "interactions", "render", "save_load" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.cardzone." .. pkg)) end

-------------------------------------------------------
-- CardZone: init & methods 
-------------------------------------------------------
function CardZone:init(gm, x, y, w, h, config) self:init_zone_attributes(gm, x, y, w, h, config) end

return CardZone
