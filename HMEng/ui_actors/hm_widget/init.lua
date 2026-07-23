local Actor = require("HMEng.actors.actor")
local HMWidget = Actor:extend()

local function install(mod) mod(HMWidget) end
local install_list = { "registry", "button.render_state", "renderers.text.render", "render", "ops", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.ui_actors.hm_widget." .. pkg)) end

function HMWidget:init(gm, args) self:init_hmwidget_attributes(gm, args or {}) end

return HMWidget
