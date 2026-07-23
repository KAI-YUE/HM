local class      = require("core.class")
local Controller = class:extend()

local function install(mod) mod(Controller) end
local install_list = { "debug", "hid.init", "registry", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.controller." .. pkg)) end

-------------------------------------------------------------------------------------------------------
-- Controller: init | The controller contains all engine logic for how human input interacts with any game object
-------------------------------------------------------------------------------------------------------
function Controller:init(gm)
    self:init_registry(gm)
    self:init_input_status()
    self:init_key_button_registry()
end
-----------------------------------------------------
-- Internal determine if the status if locked
-----------------------------------------------------
function Controller:_locked() return (self.locked and (not self.SET.pause or self.screenwipe)) or self.locks.frame or self.locks.trans or self.locks.stroked_page_child_control; end

return Controller
