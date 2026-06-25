local install_list = { "bindings", "snap", "press", "axis" }

return function(Controller)
-----------------------------------------------------
--- Buttons install
-----------------------------------------------------
for _, pkg in ipairs(install_list) do require("HMEng.controller.hid.gamepad.buttons." .. pkg)(Controller) end
end
