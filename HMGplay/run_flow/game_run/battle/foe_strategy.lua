local BattleRules = require("HMGplay.run_flow.game_run.battle.battle_rules")

local M = {}

-----------------------------
--- choose_play
----------------------------------
--- Helper: card value
local function _card_value(card)
    local base = card and card.base or {}
    return tonumber(base.value) or tonumber(base.id) or tonumber(base.rank) or tonumber(card and card.battle_foe_value) or 0
end

--- Helper: available columns
local function _available_columns(battle)
    local out = {}
    for column, data in ipairs(battle.columns or {}) do
        local zone = data.foe.zone
        if not data.locked and #zone.cards < zone.config.card_limit then out[#out + 1] = column end
    end
    return out
end

--- Helper: preview FOE result
local function _preview_foe_result(battle, data, card)
    return BattleRules.preview_with(data.foe.zone.cards, card, function(cards)
        return BattleRules.resolve(data.player.zone.cards, cards, battle.card_limit)
    end)
end

--- Helper: preview FOE upper bound
local function _preview_foe_upper(battle, data, card)
    return BattleRules.preview_with(data.foe.zone.cards, card, function(cards)
        local rank, name = BattleRules.upper_bound(cards, battle.card_limit)
        return rank or 0, name
    end)
end

--- Helper: score candidate
local function _score_candidate(battle, card, column)
    local data = battle.columns[column]
    local player_cards, foe_cards = data.player.zone.cards, data.foe.zone.cards
    local result       = _preview_foe_result(battle, data, card)
    local foe_upper    = _preview_foe_upper(battle, data, card)
    local player_upper = BattleRules.upper_bound(player_cards, battle.card_limit) or 0
    local value        = _card_value(card)
    local score        = 0

    if result and result.winner == "foe" then score = score + 10000 end
    if result and result.tie then score = score + 3000 end
    if result and result.winner == "player" then score = score - 6000 end

    score = score + 120*foe_upper - 95*player_upper
    score = score + 18*#foe_cards - 12*#player_cards
    score = score - value

    return score
end

function M.choose_play(battle)
    local hand_zone = battle.foe_hand_zone
    if not (hand_zone and hand_zone.cards and hand_zone.cards[1]) then return end

    local best, columns = nil, _available_columns(battle)
    for _, card in ipairs(hand_zone.cards) do
        for _, column in ipairs(columns) do
            local score = _score_candidate(battle, card, column)
            if not best or score > best.score then
                best = { card = card, column = column, score = score }
            end
        end
    end
    return best
end

return M
