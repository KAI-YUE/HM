local Actor         = require("HMEng.actors.actor")
local AnimDecorator = Actor:extend()

local function install(mod) mod(AnimDecorator) end
local install_list = { "registry", "render", "ops", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.ui_actors.anim_decorator." .. pkg)) end

-----------------------------
-- AnimDecorator: init & methods
-----------------------------
function AnimDecorator:init(gm, x, y, w, h, params) self:init_anim_decorator_attributes(gm, x, y, w, h, params) end

return AnimDecorator

-----
--- use instance: animated rolling_pin (folder open) for screen wipe