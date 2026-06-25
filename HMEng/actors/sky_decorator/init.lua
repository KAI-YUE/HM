local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")
local SkyDecorator  = AnimDecorator:extend()

local function install(mod) mod(SkyDecorator) end
local install_list = { "registry", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.actors.sky_decorator." .. pkg)) end

---------------------------------
--- init
---------------------------------
function SkyDecorator:init(gm, x, y, w, h, params) self:init_sky_decorator_attributes(gm, x, y, w, h, params) end

return SkyDecorator
