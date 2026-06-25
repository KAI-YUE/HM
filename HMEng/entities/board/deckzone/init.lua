local CardZone = require("HMEng.entities.board.cardzone")
local DeckZone = CardZone:extend()

local function install(mod) mod(DeckZone) end
local install_list = { "ops", "align", "render", "hover_controls" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.deckzone." .. pkg)) end

-------------------------------------------------------
-- DeckZone: init & methods 
-------------------------------------------------------
function DeckZone:init(gm, x, y, w, h, config)
    DeckZone.super.init(self, gm, x, y, w, h, config)
    self.shuffle_amt = self.config.shuffle_amt or 0
    self.hover_t = 0
end

-------------------------------------------------------
--- remove
-------------------------------------------------------
function DeckZone:remove()
    self:close_deck_view()
    self:remove_hover_controls()
    DeckZone.super.remove(self)
end

return DeckZone
