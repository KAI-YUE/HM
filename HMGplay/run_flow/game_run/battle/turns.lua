local Cards      = require("HMGplay.run_flow.game_run.battle.cards")
local BattleLog  = require("HMGplay.run_flow.game_run.battle.log")
local FoeStrategy = require("HMGplay.run_flow.game_run.battle.foe_strategy")
local Resolution = require("HMGplay.run_flow.game_run.battle.resolution")
local State      = require("HMGplay.run_flow.game_run.battle.state")

local Y, N = true, false

local M = {}

-----------------------------
--- begin_player_turn
----------------------------------
--- Helper: available columns
local function _available_columns(battle, side)
    local available = {}
    for column, data in ipairs(battle.columns) do
        local zone = data[side].zone
        if not data.locked and #zone.cards < zone.config.card_limit then available[#available + 1] = column end
    end
    return available
end

--- Helper: draw player turn card
local function _draw_player_turn_card(battle, on_done)
    local gm = battle.gm
    if not (gm.deck and gm.hand) or #gm.deck.cards == 0 then if on_done then on_done() end; return end
    gm.Fs.draw_from_to(gm, gm.deck, gm.hand, 50, "up", nil, nil, 0.05, nil, nil, nil, nil, Y)
    gm.E_MANAGER:enqueue_event({
        trigger = "after",
        delay = 0.28,
        blockable = N,
        blocking = N,
        func = function()
            if on_done then on_done() end
            return Y
        end,
    })
end

--- Helper: consume bonus
local function _consume_bonus(battle, side)
    if battle.bonus_turn ~= side then return N end
    battle.bonus_turn = nil
    if battle.bonus_hint then battle.bonus_hint.states.visible = N end
    return Y
end

function M.begin_player_turn(battle)
    if not battle.active or Resolution.battle_complete(battle) then return end
    if #_available_columns(battle, "player") == 0 then
        battle.turn, battle.busy, battle.complete = "complete", N, Y
        return
    end
    battle.turn, battle.busy = "player", Y
    _draw_player_turn_card(battle, function() battle.busy = N end)
end

-----------------------------
--- after_player_resolution
----------------------------------
function M.after_player_resolution(battle)
    if Resolution.battle_complete(battle) then return end
    if _consume_bonus(battle, "player") then return M.begin_player_turn(battle) end
    return M.play_foe_card(battle)
end

-----------------------------
--- play_foe_card
----------------------------------
function M.play_foe_card(battle)
    if not battle.active then return end
    battle.turn, battle.busy = "foe", Y
    Cards.draw_foe_battle_card(battle)

    local columns = _available_columns(battle, "foe")
    if #columns == 0 then return M.begin_player_turn(battle) end

    local hand_zone = battle.foe_hand_zone
    local play = FoeStrategy.choose_play(battle)
    local card, column = play and play.card, play and play.column
    if not card then return M.begin_player_turn(battle) end

    local foe = battle.run.parties[2]
    hand_zone:take_card(card)
    Cards.reveal_foe_card(card)
    battle.columns[column].foe.zone:add_card(card)
    battle.columns[column].foe.zone:align_cards()
    card:sync_field_presentation()
    BattleLog.add_play(battle, "foe", column, card)
    if foe then foe.discard[#foe.discard + 1] = card.battle_foe_value or 1 end
    Resolution.resolve_column(battle, column)
    battle.gm.E_MANAGER:enqueue_event({
        trigger = "after",
        delay = 0.30,
        blockable = N,
        blocking = N,
        func = function()
            if Resolution.battle_complete(battle) then return Y end
            if _consume_bonus(battle, "foe") then M.play_foe_card(battle) else M.begin_player_turn(battle) end
            return Y
        end,
    })
end

return M
