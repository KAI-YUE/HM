local Actor     = require("HMEng.actors.actor")
local BoardZone = Actor:extend()

local function install(mod) mod(BoardZone) end
local install_list = { "registry", "ops", "path", "route", "bridge", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.boardzone." .. pkg)) end

---------------------------------
--- init 
---------------------------------
function BoardZone:init(gm, x, y, w, h, config) self:init_boardzone_attributes(gm, x, y, w, h, config) end

return BoardZone
