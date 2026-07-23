local Actor = require("HMEng.actors.actor")
local Pawn  = Actor:extend()

local function install(mod) mod(Pawn) end
local install_list = { "registry" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.pawn." .. pkg)) end

local install_actions = { "zone", "move", "update" }
for _, pkg in ipairs(install_actions) do install(require("HMEng.entities.pawn.actions." .. pkg)) end

local install_factory = { "render", "set_values" }
for _, pkg in ipairs(install_factory) do install(require("HMEng.entities.pawn.in_factory." .. pkg)) end

local install_utils = { "ops", "misc" }
for _, pkg in ipairs(install_utils) do install(require("HMEng.entities.pawn.utils." .. pkg)) end

-------------------------------------------------------
-- Pawn: init & methods
-------------------------------------------------------
function Pawn:init(gm, x, y, w, h, params) self:init_pawn_attributes(gm, x, y, w, h, params) end

return Pawn
