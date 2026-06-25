local install_list = { "state", "anchor", "quad" }

return function (GridZone)
    for _, pkg in ipairs(install_list) do require("HMEng.entities.board.gridzone.focus_projection." .. pkg)(GridZone) end
end
