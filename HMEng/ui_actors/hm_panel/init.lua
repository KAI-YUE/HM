local Actor = require("HMEng.actors.actor")
local HMPanel = Actor:extend()

local function install(mod) mod(HMPanel) end
local install_list = { "registry", "render", "ops", "prototype_ops.switch_stroked_page", "prototype_ops.switch_art_page" }
for _, pkg in ipairs(install_list) do install(require("HMEng.ui_actors.hm_panel." .. pkg)) end

---____________________________
--- main: init
---______________________________________
function HMPanel:init(gm, args) self:init_hmpanel_attributes(gm, args or {}) end

return HMPanel
