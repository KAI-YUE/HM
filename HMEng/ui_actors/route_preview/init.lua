local Actor = require("HMEng.actors.actor")
local RoutePreview = Actor:extend()

local function install(mod) mod(RoutePreview) end
local install_list = { "registry", "layout", "draw", "ops", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.ui_actors.route_preview." .. pkg)) end

return RoutePreview
