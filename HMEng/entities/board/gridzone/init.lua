local Actor    = require("HMEng.actors.actor")
local GridZone = Actor:extend()

local function install(mod) mod(GridZone) end
local install_list = { "registry", "ops", "focus_projection", "align", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.gridzone." .. pkg)) end

--------------------------------------------
--- init 
--------------------------------------------
function GridZone:init(gm, x, y, w, h, config) self:init_gridzone_attributes(gm, x, y, w, h, config) end

return GridZone
