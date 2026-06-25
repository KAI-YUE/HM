local Actor = require("HMEng.actors.actor")
local Wallpaper = Actor:extend()

local function install(mod) mod(Wallpaper) end
local install_list = { "registry", "ops", "render.shader", "render.drift", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.bg.wallpaper." .. pkg)) end

--------------------------------
--- init
--------------------------------
function Wallpaper:init(gm, args) self:init_wallpaper_attributes(gm, args) end

return Wallpaper
