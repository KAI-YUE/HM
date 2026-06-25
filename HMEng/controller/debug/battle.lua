local Battle = require("HMGplay.run_flow.game_run.battle")

local Y = true

local M = {}

--------------------------------------------------
--- Main: trigger battle from hovered pawn
--------------------------------------------------
function M.handle(ctrl, key)
    local gm = ctrl.gm or G
    if key == "v" then
        local battle = gm and gm.run_loop and gm.run_loop.battle
        if battle and battle.active then return Battle.quick_victory(battle) end
    end
    if key ~= "b" then return end
    local Pawn = require("HMEng.entities.pawn")
    local pawn = ctrl.hovering and ctrl.hovering.target
    if not (pawn and pawn:is(Pawn) and gm and gm.run_loop) then return end
    Battle.start(gm.run_loop, pawn, { debug = Y })
    return Y
end

return M
