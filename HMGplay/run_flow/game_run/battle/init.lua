local Cards     = require("HMGplay.run_flow.game_run.battle.cards")
local BattleLog = require("HMGplay.run_flow.game_run.battle.log")
local Layout    = require("HMGplay.run_flow.game_run.battle.layout")
local Placement = require("HMGplay.run_flow.game_run.battle.placement")
local Resolution = require("HMGplay.run_flow.game_run.battle.resolution")
local Rewards   = require("HMGplay.run_flow.game_run.battle.rewards")
local State     = require("HMGplay.run_flow.game_run.battle.state")
local Turns     = require("HMGplay.run_flow.game_run.battle.turns")

local Y, N = true, false

local M = {}

-----------------------------
--- placement API
----------------------------------
function M.snap_dragged_card(battle, card) return Placement.snap_dragged_card(battle, card) end
function M.stage_card(battle, card, column) return Placement.stage_card(battle, card, column) end
function M.dismiss_dragged_card_if_far(battle, card, ctrl) return Placement.dismiss_dragged_card_if_far(battle, card, ctrl) end
function M.undo(battle) return Placement.undo(battle) end
function M.play_or_confirm(battle) return Placement.play_or_confirm(battle) end
function M.quick_victory(battle) return Resolution.quick_victory(battle) end

-----------------------------
--- start
----------------------------------
function M.start(run, source_pawn, opts)
    if not run or run.battle and run.battle.active then return run and run.battle end
    opts = opts or {}

    local battle = {
        active                 = Y,
        busy                   = N,
        turn                   = "player",
        card_limit             = 4,
        column_count           = 4,
        columns                = {},
        placements             = {},
        log                    = BattleLog.new(),
        log_open               = N,
        auto_confirm_placement = Y,
        claimed                = { player = {}, foe = {} },
        gm                     = run.gm,
        run                    = run,
        foe                    = require("HMGplay.run_flow.game_run.foe"),
        source_pawn            = source_pawn,
        debug_battle           = opts.debug == Y,
    }
    battle.reward_pool = Rewards.build(battle.column_count)
    battle.stop_battle = function() return M.stop(battle) end
    run.battle = battle
    run.busy   = Y
    battle.hand_highlighted_limit = run.gm.hand.config.highlighted_limit
    if run.gm.hand.unhighlight_all then run.gm.hand:unhighlight_all() end
    run.gm.hand.config.highlighted_limit = 1
    local foe = run.parties[2]
    if foe and foe.hand and foe.deck then
        foe.affection_round = 0
        foe.affection = foe.affection or 0
        for idx = #foe.hand, 1, -1 do foe.deck[#foe.deck + 1] = foe.hand[idx] end
        foe.hand = {}
    end
    if run.move_button then run.move_button.states.visible = N end
    if run.foe_preview then run.foe_preview.states.visible = N end
    if run.board then run.board:clear_move_preview() end
    State.cache_hand(battle)
    State.hide_map(battle)
    Layout.build_field(run.gm, battle, M)
    Cards.fill_foe_hand(battle)
    Cards.refresh_foe_deck_visual(battle)
    Turns.begin_player_turn(battle)
    return battle
end

-----------------------------
--- stop
----------------------------------
function M.stop(battle)
    if not (battle and battle.active) then return end
    battle.active = N
    State.remove_field(battle)
    if battle.bg and not battle.bg.REMOVED then
        battle.bg.children = {}
        battle.bg:remove()
    end
    State.restore_map(battle)
    State.restore_hand_layout(battle)
    battle.gm.hand.config.highlighted_limit = battle.hand_highlighted_limit
    battle.run.battle = nil
    battle.run.busy = N
    return Y
end

return M
