local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")
local Chara         = AnimDecorator:extend()

local function install(mod) mod(Chara) end
local install_list = { "registry", "move", "render", "ops", "update", }
for _, pkg in ipairs(install_list) do install(require("HMEng.chara." .. pkg)) end

-------------------------------------------------------
-- Chara: init & methods
-------------------------------------------------------
function Chara:init(gm, x, y, w, h, params)
    self:init_chara_attributes(gm, x, y, w, h, params)
end

return Chara
