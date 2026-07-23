local BattleRules = require("HMGplay.run_flow.game_run.battle.battle_rules")
local Conclusion  = require("HMGplay.run_flow.game_run.battle.conclusion")
local Rewards     = require("HMGplay.run_flow.game_run.battle.rewards")

local Y, N = true, false

local M = {}

-----------------------------
--- resolve_column
----------------------------------
--- Helper: reward text
local function _reward_text(column, result)
    if result.tie then return "Tied" end
    local owner = result.winner == "player" and "Player" or "FOE"
    return owner .. " claimed " .. tostring(column)
end

--- Helper: show bonus hint
local function _show_bonus_hint(battle, winner)
    battle.bonus_turn      = winner
    battle.bonus_hint_text = (winner == "player" and "Player" or "FOE") .. " Bonus"
    if battle.bonus_hint then battle.bonus_hint.states.visible = Y end
    battle.gm.E_MANAGER:enqueue_event({
        trigger = "after", delay = 0.85, blockable = N, blocking = N,
        func = function()
            if battle.bonus_hint and battle.bonus_turn ~= winner then battle.bonus_hint.states.visible = N end
            return Y
        end,
    })
end

--- Helper: claim reward
local function _claim_reward(battle, column, result)
    local data = battle.columns[column]
    data.resolution = result
    data.locked     = result.locked
    if result.winner then
        Rewards.claim(battle, data.reward, result.winner)
        _show_bonus_hint(battle, result.winner)
    end

    local reward = data.reward.actor
    if reward then
        reward.draw_alpha = result.tie and 0.45 or 0.72
        reward.battle_reward_result = _reward_text(column, result)
    end
end

function M.resolve_column(battle, column)
    local data = battle.columns[column]
    if not data or data.locked then return end
    local result = BattleRules.resolve(data.player.zone.cards, data.foe.zone.cards, battle.card_limit)
    if result then _claim_reward(battle, column, result) end
end

-----------------------------
--- battle_complete
----------------------------------
function M.battle_complete(battle)
    for _, data in ipairs(battle.columns) do if not data.locked then return N end end
    battle.complete = Y
    battle.turn, battle.busy = "complete", N
    Conclusion.open(battle)
    return Y
end

-----------------------------
--- quick_victory
----------------------------------
function M.quick_victory(battle)
    if not (battle and battle.active) then return end
    for column, data in ipairs(battle.columns or {}) do
        if not data.locked then _claim_reward(battle, column, { winner = "player", locked = Y }) end
    end
    battle.complete, battle.turn, battle.busy, battle.bonus_turn = Y, "complete", N, nil
    if battle.bonus_hint then battle.bonus_hint.states.visible = N end
    Conclusion.open(battle)
    return Y
end

return M
