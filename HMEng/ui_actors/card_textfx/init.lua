local Actor      = require("HMEng.actors.actor")
local CardTextFx = Actor:extend()

local function install(mod) mod(CardTextFx) end
local install_list = { "registry", "ops", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.ui_actors.card_textfx." .. pkg)) end

local install_factory_list = { "sample_font", "build.bounds", "build.letter", "build", "render" }
for _, pkg in ipairs(install_factory_list) do install(require("HMEng.ui_actors.card_textfx.in_factory." .. pkg)) end

---____________________________
--- main: init
---______________________________________
function CardTextFx:init(gm, config) self:init_card_textfx_attributes(gm, config) end
function CardTextFx:_data_fonts()    return self.data_fonts end

return CardTextFx
