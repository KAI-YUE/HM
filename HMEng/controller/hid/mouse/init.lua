return function(Controller)
-------------------------------------------------
--- Mouse Install
-------------------------------------------------
local install_list = { "cursor.init", "scroll" }
for _, pkg in ipairs(install_list) do require("HMEng.controller.hid.mouse." .. pkg)(Controller) end
end
