local Helpers = require("HMGplay.run_flow.game_run.helpers")
local Foe     = require("HMGplay.run_flow.game_run.foe")

local Y, N = true, false

local M = {}

-----------------------------
--- begin_player_turn
----------------------------------
--- Helper: begin player turn
local function _begin_player_turn(run)
    local gm = run.gm
    run.turn, run.busy = 1, Y
    Helpers.clear_player_move_options(run)
    gm.g_state, gm.state_comp = gm.g_states.idle, N
    gm.Fs.draw_deck2hand(gm)
    gm.E_MANAGER:enqueue_event({
        trigger = "after",
        delay = 0.35,
        blockable = N,
        blocking = N,
        func = function()
            gm.g_state, gm.state_comp, run.busy = gm.g_states.idle, N, N
            Foe.refresh_foe_preview(run)
            return Helpers.refresh_player_move_options(run)
        end,
    })
end

-----------------------------
--- play_selected_card
----------------------------------
--- Helper: play selected card
local function _play_selected_card(run)
    if run.battle and run.battle.active or run.busy or run.turn ~= 1 then return end
    local card  = run.gm.hand and run.gm.hand.highlighted[1]
    local value = Helpers.card_value(card)
    local plan  = Helpers.refresh_player_move_options(run)
    if not card or value <= 0 or not plan or #plan.endpoints == 0 then return end

    run.busy = Y
    if run.foe_preview then run.foe_preview.states.visible = N end
    run.gm.hand:remove_card(card)
    run.gm.discard:emplace(card)
    Helpers.clear_player_move_options(run)
    Helpers.move_pawn(run, run.parties[1].pawn, value, function()
        Foe.play_foe_turn(run)
    end, Y)
end

M.begin_player_turn = _begin_player_turn
M.play_selected_card  = _play_selected_card

return M
