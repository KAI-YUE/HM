local class = require("core.class")
local GEvent = class:extend()

local function install(mod) mod(GEvent) end
local install_list = { "registry", "handle" }
for _, pkg in ipairs(install_list) do install(require("HMEng.events.game_event." .. pkg)) end

-------------------------------------------------------
-- GEvent: init 
-------------------------------------------------------
function GEvent:init(config) self:init_event_attributes(config) end

return GEvent