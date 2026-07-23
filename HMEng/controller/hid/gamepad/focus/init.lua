return function(Controller)
--------------------------------------------------------
--- Focus Install
--------------------------------------------------------
local install_list = { "update", "input" }
for _, pkg in ipairs(install_list) do require("HMEng.controller.hid.gamepad.focus." .. pkg)(Controller) end
end
