local Conclusion = require("HMGplay.run_flow.game_run.battle.conclusion")

local Y, N = true, false

local M = {}

-----------------------------
--- helpers
----------------------------
--- Helper: remove actor
local function _remove_actor(actor) if actor and not actor.REMOVED then actor:remove() end end

-----------------------------
--- hide_map
----------------------------------
--- Helper: cache actor state
local function _cache_actor_state(cache, actor)
    if not (actor and actor.states) or cache[actor] then return end
    local st = actor.states
    cache[actor] = {
        visible = st.visible,
        collide = st.collide and st.collide.can,
        hover   = st.hover and st.hover.can,
        click   = st.click and st.click.can,
        drag    = st.drag and st.drag.can,
    }
    st.visible = N
    if st.collide then st.collide.can = N end
    if st.hover then st.hover.can = N end
    if st.click then st.click.can = N end
    if st.drag then st.drag.can = N end
end

function M.hide_map(battle)
    local gm, cache = battle.gm, {}
    _cache_actor_state(cache, gm.field)
    _cache_actor_state(cache, gm.gridzone)
    _cache_actor_state(cache, gm.bg)
    for _, actor in ipairs(gm.sky_decorators or {}) do _cache_actor_state(cache, actor) end
    for _, pawn in ipairs(gm.R and gm.R.PAWN or {}) do _cache_actor_state(cache, pawn) end
    for _, chara in ipairs(gm.R and gm.R.CHARA or {}) do _cache_actor_state(cache, chara) end
    battle.map_state = cache
end

-----------------------------
--- restore_map
----------------------------------
function M.restore_map(battle)
    for actor, saved in pairs(battle.map_state or {}) do
        if not actor.REMOVED and actor.states then
            local st = actor.states
            st.visible = saved.visible
            if st.collide then st.collide.can = saved.collide end
            if st.hover then st.hover.can = saved.hover end
            if st.click then st.click.can = saved.click end
            if st.drag then st.drag.can = saved.drag end
        end
    end
    battle.map_state = nil
end

-----------------------------
--- cache_hand
----------------------------------
function M.cache_hand(battle)
    local hand = battle.gm and battle.gm.hand
    if not hand then return end
    local T = hand.T or {}
    local cards = {}
    for idx, card in ipairs(hand.cards or {}) do cards[idx] = card end
    battle.hand_state = {
        T         = { x = T.x, y = T.y, w = T.w, h = T.h, r = T.r },
        cards     = cards,
    }
end

-----------------------------
--- restore_hand_layout
----------------------------------
--- Helper: same hand cards
local function _same_hand_cards(hand, saved)
    local cards = saved and saved.cards or {}
    if #(hand.cards or {}) ~= #cards then return N end
    for idx, card in ipairs(cards) do if hand.cards[idx] ~= card then return N end end
    return Y
end

--- Helper: clear hand fan cache
local function _clear_hand_fan_cache(hand)
    if hand.clear_fan_anchor_cache then hand:clear_fan_anchor_cache() end
    if hand.clear_fan_grab_jitter then hand:clear_fan_grab_jitter() end
end

function M.restore_hand_layout(battle)
    local hand, saved = battle.gm and battle.gm.hand, battle.hand_state
    if not (hand and saved) then return end
    local T = saved.T or {}
    if hand.hard_set_T then hand:hard_set_T(T.x, T.y, T.w, T.h)
    elseif hand.T then
        hand.T.x, hand.T.y, hand.T.w, hand.T.h, hand.T.r = T.x, T.y, T.w, T.h, T.r
    end
    if saved.alignment and _same_hand_cards(hand, saved) and hand.restore_alignment_state then hand:restore_alignment_state(saved.alignment)
    else _clear_hand_fan_cache(hand) end
    if hand.align_cards then hand:align_cards() end
end

-----------------------------
--- restore_hand_card
----------------------------------
function M.restore_hand_card(hand, card)
    hand:emplace(card)
    card.states.drag.can = Y
    card.states.collide.can = Y
    card.states.click.can = Y
end

-----------------------------
--- remove_zone_cards
----------------------------------
function M.remove_zone_cards(zone, on_card)
    while zone and zone.cards and zone.cards[1] do
        local card = zone:take_card(zone.cards[1])
        if on_card then on_card(card)
        else card:remove() end
    end
end

-----------------------------
--- remove_field
----------------------------------
function M.remove_field(battle)
    local gm = battle.gm
    Conclusion.close(battle)
    _remove_actor(battle.play_button)
    _remove_actor(battle.undo_button)
    _remove_actor(battle.log_button)
    _remove_actor(battle.log_panel)
    _remove_actor(battle.bonus_hint)
    M.remove_zone_cards(battle.foe_deck_zone)
    M.remove_zone_cards(battle.foe_hand_zone)
    if battle.foe_deck_zone and not battle.foe_deck_zone.REMOVED then battle.foe_deck_zone:remove() end
    if battle.foe_hand_zone and not battle.foe_hand_zone.REMOVED then battle.foe_hand_zone:remove() end
    if battle.pending_zone and not battle.pending_zone.REMOVED then
        M.remove_zone_cards(battle.pending_zone, function(card) M.restore_hand_card(gm.hand, card) end)
        battle.pending_zone:remove()
    end
    for _, data in ipairs(battle.columns or {}) do
        _remove_actor(data.reward.actor)
        _remove_actor(data.reward.score_panel)
        for _, side in ipairs({ "player", "foe" }) do
            local zone = data[side].zone
            while zone and zone.cards and zone.cards[1] do
                local card = zone:take_card(zone.cards[1])
                if side == "player" then gm.discard:emplace(card) else card:remove() end
            end
            if zone and not zone.REMOVED then zone:remove() end
        end
    end
end

return M
