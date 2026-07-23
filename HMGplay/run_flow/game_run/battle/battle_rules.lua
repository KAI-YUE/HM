local HandEva = require("HMGplay.rules.hand_eva")

local M = {}

local HAND_RANK = {
    ["High Card"]       = 1,
    ["Pair"]            = 2,
    ["Two Pair"]        = 3,
    ["Three of a Kind"] = 4,
    ["Straight"]        = 5,
    ["Flush"]           = 6,
    ["Four of a Kind"]  = 7,
    ["Straight Flush"]  = 8,
}

M.HAND_RANK = HAND_RANK

-----------------------------
--- rank
----------------------------------
--- Helper: four-card hand facts
local function _facts(cards)
    local facts = { count = #cards, ranks = {}, suits = {}, rank_values = {}, max_rank_count = 0 }
    for _, card in ipairs(cards) do
        local base               = card.base or {}
        local rank               = tonumber(base.id) or tonumber(base.value) or tonumber(base.rank) or 0
        local suit               = tostring(base.suit or "")
        facts.ranks[rank]        = (facts.ranks[rank] or 0) + 1
        facts.suits[suit]        = (facts.suits[suit] or 0) + 1
        facts.max_rank_count     = math.max(facts.max_rank_count, facts.ranks[rank])
    end
    for rank in pairs(facts.ranks) do facts.rank_values[#facts.rank_values + 1] = rank end
    table.sort(facts.rank_values)
    return facts
end

--- Helper: one-suit check
local function _one_suit(facts)
    local count = 0
    for _ in pairs(facts.suits) do count = count + 1 end
    return count <= 1
end

--- Helper: straight possibility
local function _straight_possible(facts, remaining)
    local values = facts.rank_values
    if #values ~= facts.count or #values + remaining < 4 then return false end
    if #values == 0 then return remaining >= 4 end
    return values[#values] - values[1] <= 3
end

--- Helper: first card gm
local function _gm_for_cards(cards) local card = cards and cards[1]; return card and card.gm end

--- Helper: battle suits
local function _battle_suits(cards)
    local seen, suits = {}, {}
    for _, card in ipairs(cards or {}) do
        local suit = card.base and card.base.suit
        if suit and not seen[suit] then seen[suit] = true; suits[#suits + 1] = suit end
    end
    return suits
end

--- Helper: gameplay hand evaluator bridge
local function _rank_with_hand_eva(cards, card_limit)
    local gm = _gm_for_cards(cards)
    local results = HandEva.evaluate_hand(gm, cards, {
        max_play      = card_limit or 4,
        ignore_jokers = true,
        suits         = _battle_suits(cards),
    })
    for _, name in ipairs({
        "Straight Flush",
        "Four of a Kind",
        "Flush",
        "Straight",
        "Three of a Kind",
        "Two Pair",
        "Pair",
    }) do
        if results[name] and next(results[name]) then return HAND_RANK[name], name end
    end
end

function M.rank(cards, card_limit)
    local facts = _facts(cards)
    card_limit = card_limit or 4
    if facts.count ~= card_limit then return 0, "Incomplete" end

    local eva_rank, eva_name = _rank_with_hand_eva(cards, card_limit)
    if eva_rank then return eva_rank, eva_name end

    local straight   = _straight_possible(facts, 0)
    local flush      = _one_suit(facts)
    local pair_count = 0
    for _, count in pairs(facts.ranks) do if count >= 2 then pair_count = pair_count + 1 end end

    local name
    if straight and flush then name = "Straight Flush"
    elseif facts.max_rank_count == 4 then name = "Four of a Kind"
    elseif flush then name = "Flush"
    elseif straight then name = "Straight"
    elseif facts.max_rank_count == 3 then name = "Three of a Kind"
    elseif pair_count >= 2 then name = "Two Pair"
    elseif pair_count == 1 then name = "Pair"
    else name = "High Card" end
    return HAND_RANK[name], name
end

-----------------------------
--- upper_bound
----------------------------------
--- Helper: two-pair possibility
local function _two_pair_possible(facts, remaining)
    local needs = {}
    for _, count in pairs(facts.ranks) do needs[#needs + 1] = math.max(0, 2 - count) end
    while #needs < 2 do needs[#needs + 1] = 2 end
    table.sort(needs)
    return needs[1] + needs[2] <= remaining
end

function M.upper_bound(cards, card_limit)
    local facts     = _facts(cards)
    local remaining = math.max(0, (card_limit or 4) - facts.count)
    if remaining == 0 then return M.rank(cards, card_limit) end

    if _one_suit(facts) and _straight_possible(facts, remaining) then return HAND_RANK["Straight Flush"], "Straight Flush" end
    if facts.max_rank_count + remaining >= 4 then return HAND_RANK["Four of a Kind"], "Four of a Kind" end
    if _one_suit(facts) then return HAND_RANK["Flush"], "Flush" end
    if _straight_possible(facts, remaining) then return HAND_RANK["Straight"], "Straight" end
    if facts.max_rank_count + remaining >= 3 then return HAND_RANK["Three of a Kind"], "Three of a Kind" end
    if _two_pair_possible(facts, remaining) then return HAND_RANK["Two Pair"], "Two Pair" end
    if facts.max_rank_count >= 2 or remaining >= 1 then return HAND_RANK["Pair"], "Pair" end
    return HAND_RANK["High Card"], "High Card"
end

-----------------------------
--- preview_with
----------------------------------
function M.preview_with(cards, card, fn)
    cards[#cards + 1] = card
    local ret = fn(cards)
    cards[#cards] = nil
    return ret
end

-----------------------------
--- resolve
----------------------------------
function M.resolve(player_cards, foe_cards, card_limit)
    local player_full = #player_cards >= card_limit
    local foe_full    = #foe_cards >= card_limit
    if not player_full and not foe_full then return end

    if player_full and foe_full then
        local player_rank, player_name = M.rank(player_cards, card_limit)
        local foe_rank, foe_name       = M.rank(foe_cards, card_limit)
        if player_rank == foe_rank then return { locked = true, tie = true, player_rank = player_name, foe_rank = foe_name } end
        return {
            locked      = true,
            winner      = player_rank > foe_rank and "player" or "foe",
            player_rank = player_name,
            foe_rank    = foe_name,
        }
    end

    local full_side              = player_full and "player" or "foe"
    local full_cards             = player_full and player_cards or foe_cards
    local open_cards             = player_full and foe_cards or player_cards
    local full_rank, full_name   = M.rank(full_cards, card_limit)
    local upper_rank, upper_name = M.upper_bound(open_cards, card_limit)
    if full_rank > upper_rank then return { locked = true, winner = full_side, early = true, full_rank = full_name, upper_bound = upper_name } end
end

return M
