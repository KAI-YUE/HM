local RoutePreview = require("HMEng.ui_actors.route_preview")
local Helpers  = require("HMGplay.run_flow.game_run.helpers")
local Foe      = require("HMGplay.run_flow.game_run.foe")
local Hud      = require("HMGplay.run_flow.game_run.mod_hud")
local Turns    = require("HMGplay.run_flow.game_run.turns")
local UI       = require("HMGplay.run_flow.game_run.ui")

local Y, N = true, false

local M = {}

-----------------------------
--- prepare
----------------------------------
function M.prepare(gm, opts)
    local party_count = math.max(2, math.floor((opts and opts.party_count) or 2))
    gm.run_loop = { gm = gm, party_count = party_count, foe_hand_size = 5, turn = 1, busy = Y, parties = {} }
    return gm.run_loop
end

-----------------------------
--- start
----------------------------------
function M.start(gm)
    local run = gm.run_loop
    if not run then return end

    run.board = gm.field
    run.board:enable_bridge_interaction(N)
    run.board:set_path_selection_handler(function(_, cell)
        return Helpers.select_player_branch(run, cell)
    end)
    run.on_begin_player_turn = Turns.begin_player_turn

    for i = 1, run.party_count do
        run.parties[i] = {
            pawn    = gm.party_pawns and gm.party_pawns[i],
            deck    = i == 1 and gm.deck or {},
            hand    = i == 1 and gm.hand or {},
            discard = i == 1 and gm.discard or {},
        }
    end

    if run.parties[2] then
        run.parties[2].deck = Foe.new_foe_deck()
        run.parties[2].hand = {}
        run.parties[2].discard = {}
        Foe.draw_foe(run)
    end

    Hud.create(gm, run)
    run.move_button = UI.make_move_button(gm, run)
    run.foe_preview = RoutePreview(gm, { run = run })
    Turns.begin_player_turn(run)
    return run
end

return M
