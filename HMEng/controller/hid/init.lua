return function(Controller)
-------------------------------------------------
--- HID Install
-------------------------------------------------
local install_list = { "secondary_action", "keys", "gamepad.init", "mouse.init" }
for _, pkg in ipairs(install_list) do require("HMEng.controller.hid." .. pkg)(Controller) end
end
