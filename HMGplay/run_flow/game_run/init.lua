local RoutePreview = require("HMEng.ui_actors.route_preview")
local Helpers  = require("HMGplay.run_flow.game_run.helpers")
local Foe      = require("HMGplay.run_flow.game_run.foe")
local Hud      = require("HMGplay.run_flow.game_run.mod_hud")
local Turns    = require("HMGplay.run_flow.game_run.turns")
local UI       = require("HMGplay.run_flow.game_run.ui")
local IntroTime = require("HMfns.animate.start.intro_timeline")

local Y, N = true, false

local M = {}

--- Helper: unlock intro-started player turn
local function _finish_intro_player_turn(run)
    local gm = run.gm
    run.turn, run.busy = 1, N
    Helpers.clear_player_move_options(run)
    gm.g_state, gm.state_comp = gm.g_states.idle, N
    Foe.refresh_foe_preview(run)
    return Helpers.refresh_player_move_options(run)
end

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
function M.start(gm, opts)
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
    if opts and opts.silent_start then Turns.begin_player_turn(run)
    else gm.E_MANAGER:enqueue_event({ trigger = "after", delay = (IntroTime.hand.drag_sort or 0) + 0.2, blockable = N, func = function() return _finish_intro_player_turn(run) end }) end
    return run
end

return M
