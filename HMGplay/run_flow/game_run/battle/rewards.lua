local Card = require("HMEng.entities.card")
local Hud  = require("HMGplay.run_flow.game_run.mod_hud")

local Y, N = true, false

local M = {}

local POOL = {
    { id = "milk",     name = "Milk",     score = 4, icon = "milk",     fullness = 12, card_value = 4, affection = 1 },
    { id = "muffin",   name = "Muffin",   score = 6, icon = "muffin",   fullness = 18, card_value = 6, affection = 2 },
    { id = "tea",      name = "Tea",      score = 3, icon = "teapng",   fullness = 9,  card_value = 3, affection = 1 },
    { id = "gift_box", name = "Gift Box", score = 8, icon = "coin",     fullness = 6,  card_value = 8, affection = 3 },
}

-----------------------------
--- setup
----------------------------
--- Helper: pool item
local function _pool_item(idx)
    local base = POOL[((idx - 1)%#POOL) + 1]
    return { id = base.id, name = base.name, score = base.score, icon = base.icon, fullness = base.fullness, card_value = base.card_value, affection = base.affection }
end

function M.build(column_count)
    local rewards = {}
    for idx = 1, column_count do
        local reward = _pool_item(idx)
        reward.column, reward.revealed = idx, idx <= 2
        rewards[idx] = reward
    end
    return rewards
end

-----------------------------
--- reveal
----------------------------
--- Helper: first pair claimed
local function _first_pair_claimed(battle)
    return battle.columns[1] and battle.columns[1].reward.claimed and battle.columns[2] and battle.columns[2].reward.claimed
end

--- Helper: score text
local function _score_text(reward)
    if not reward then return "?" end
    return reward.revealed and tostring(reward.score) or "?"
end

function M.refresh_reveals(battle)
    local reveal_late = _first_pair_claimed(battle)
    for column, data in ipairs(battle.columns or {}) do
        local reward = data.reward
        if reward.claimed or reveal_late then reward.revealed = Y end
        local panel = reward.score_panel
        if panel and panel.widget then panel.widget.config.text = _score_text(reward) end
    end
end

-----------------------------
--- claim
----------------------------
--- Helper: claimed T
local function _claimed_T(battle, owner, idx)
    local RT = battle.gm._room and battle.gm._room.T or { w = 24, h = 13.5 }
    local x = owner == "player" and (0.95 + (idx - 1)*0.78) or (RT.w - 1.72 - (idx - 1)*0.78)
    local y = owner == "player" and (RT.h - 4.05) or 3.15
    return x, y, 0.56, 0.56
end

function M.claim(battle, reward, owner)
    reward.claimed, reward.owner, reward.revealed = Y, owner, Y
    battle.claimed[owner][#battle.claimed[owner] + 1] = reward
    local idx = #battle.claimed[owner]
    local x, y, w, h = _claimed_T(battle, owner, idx)
    if reward.actor and reward.actor.hard_set_T then reward.actor:hard_set_T(x, y, w, h) end
    if reward.score_panel and reward.score_panel.hard_set_T then reward.score_panel:hard_set_T(x + 0.18, y + h - 0.18, 0.38, 0.28) end
    M.refresh_reveals(battle)
end

-----------------------------
--- actions
----------------------------
--- Helper: gameplay
local function _gameplay(gm) return gm and gm.GAME and (gm.GAME.gameplay or gm.GAME.starting_params) or gm and gm.GAME or {} end

--- Helper: reward card base
local function _reward_card_base(reward)
    local value = math.max(1, math.min(10, tonumber(reward.card_value or reward.score) or 1))
    return { suit = "F", rank = tostring(value), rank_label = tostring(value), value = value, name = "reward_" .. tostring(reward.id or reward.column) }
end

function M.eat(battle, reward)
    local gm, val = battle.gm, tonumber(reward.fullness or reward.score) or 0
    local gp = _gameplay(gm)
    gp.fullness = math.min(gp.full_max or gp.fullness_max or 100, (gp.fullness or gp.full or 0) + val)
    if gp.full ~= nil then gp.full = gp.fullness end
    Hud.refresh(gm, battle.run)
end

function M.print_card(battle, reward)
    local gm = battle.gm
    if not gm.hand then return end
    local card = Card(gm, gm.hand.T.x, gm.hand.T.y, gm.card_w, gm.card_h, _reward_card_base(reward), gm.CMod.c_base, { facing = "front" })
    gm.hand:emplace(card)
    if gm.hand.align_cards then gm.hand:align_cards() end
end

function M.send_gift(battle, reward)
    local foe = battle.run.parties[2]; if not foe then return end
    foe.affection_round = (foe.affection_round or 0) + (reward.affection or 1)
    foe.affection       = (foe.affection or 0) + (reward.affection or 1)
end

function M.discard(battle, reward)
    reward.discarded = Y
    if reward.actor and not reward.actor.REMOVED then reward.actor:remove() end
    if reward.score_panel and not reward.score_panel.REMOVED then reward.score_panel:remove() end
end

function M.apply_action(battle, reward, action)
    if not (battle and reward) or reward.action then return end
    if     action == "eat"        then M.eat(battle, reward)
    elseif action == "print_card" then M.print_card(battle, reward)
    elseif action == "send_gift"  then M.send_gift(battle, reward)
    elseif action == "discard"    then M.discard(battle, reward)
    else return end
    reward.action = action
    return Y
end

return M
