local install_list = {
    "hooks",
    "panel",
    "view",
    "state",
}

return function (DeckZone)
--------------------------------------------------
--- install hover control modules
--------------------------------------------------
local function install(mod) mod(DeckZone) end
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.deckzone.hover_controls." .. pkg)) end

end
