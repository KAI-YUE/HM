local Actor   = require("HMEng.actors.actor")
local Spritor = Actor:extend()

local function install(mod) mod(Spritor) end
local install_list = { "registry", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.actors.spritor." .. pkg)) end

-------------------------------------------------------
-- Spritor: init & Methods
-------------------------------------------------------
function Spritor:init(gm, x, y, w, h, atlas, key, lock_wh_ratio) self:init_spritor_attributes(gm, x, y, w, h, atlas, key, lock_wh_ratio) end
function Spritor:reset() end

return Spritor
