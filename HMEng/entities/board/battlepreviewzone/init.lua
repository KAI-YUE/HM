local CardZone       = require("HMEng.entities.board.cardzone")
local Projector      = require("core.transform.projector")
local BattlePreviewZone = CardZone:extend()

local function install(mod) mod(BattlePreviewZone) end
local install_list = { "layout", "ops", "render" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.board.battlepreviewzone." .. pkg)) end

--------------------------------------------------
--- init
--------------------------------------------------
function BattlePreviewZone:init(gm, x, y, w, h, config)
    BattlePreviewZone.super.init(self, gm, x, y, w, h, config)
    self.projector = Projector(x, y, w, h, { rcfg = gm.rcfg, room = gm._room })
    self.layout = nil
end

return BattlePreviewZone
