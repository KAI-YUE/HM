local install_list = {
    "dialogue",
    "input",
    "state",
    "dispatch",
}

return function(Controller)
--------------------------------------------------------
--- Update Install
--------------------------------------------------------
for _, pkg in ipairs(install_list) do
    require("HMEng.controller.update." .. pkg)(Controller)
end
end
