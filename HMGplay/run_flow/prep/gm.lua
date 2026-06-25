local Deck = require("HMEng.entities.deck")

local M = {}

-----------------------------
--- prepare_for_gm
----------------------------------
function M.prepare_for_gm(gm, args)
    args = args or {}
    local _stg = args.stage or gm.stages.run_tut

    gm.saved_game, gm.g_stage = nil, _stg

    gm:delete_run()
    gm:prep_stage(_stg, gm.g_states.idle)

    gm.state_comp = false
    gm:init_game_manager()

    local gG = gm.GAME
    gG.selected_back      = Deck(gm)
    gG.pseudorandom.seed = args.seed or ((args.stage == gm.stages.run_tut) and "tut") or gG.pseudorandom.seed
    gG.stake, gG.challenge = args.stake, args.challenge

    for k, v in pairs(gG.pseudorandom) do if v == 0 then gG.pseudorandom[k] = pseudohash(k .. gG.pseudorandom.seed) end end

    gG.pseudorandom.hashed_seed = pseudohash(gG.pseudorandom.seed)
    gm:save_settings()
end

return M
