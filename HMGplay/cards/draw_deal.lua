local TabUtils  = require("HMfns.utils.table_utils")
local SND, RNG  = require("HMfns.utils.sound_utils"), require("HMfns.utils.math.rng_utils")
local TMR       = require("HMfns.systems.timer")

local sleep        = TMR.sleep
local contains     = TabUtils.contains
local shuffle      = TabUtils.shuffle_in_place
local seeded_rand  = RNG.seeded_random
local play_clip    = SND.play_clip
 
local min, max  = math.min, math.max
local rad, abs  = math.rad, math.abs
local rand     = math.random
local Y, N     = true, false

--- Helper: clamp
local function clamp(v, lo, hi) if lo > hi then return 0.5*(lo + hi) end; return max(lo, min(hi, v)) end

local M = {}
-------------------------------------------------
-- draw from to 
-------------------------------------------------
--- Helper: clear visual-only dealing state
local function _schedule_clear_dealing(gm, card)
    local wp = card and card.waypoint_T
    if not wp then return end

    local EM = gm.E_MANAGER
    local function enqueue_ease(delay, ease, ref_table, ref_value, ease_to) EM:enqueue_event({ trigger = "ease", delay = delay, ease = ease, blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to }) end
    local function enqueue_after(delay, func)  EM:enqueue_event({ queue = "card_dealing", trigger = "after", delay = delay, blockable = N, func = function()  return func() end }); return Y end

    local delay = 1.7
    if card.shadow_parallax then
        card.shadow_parallax.y = 0.8
        enqueue_ease(delay, "sine", card.shadow_parallax, "y", -0.1)
    end
    enqueue_after(delay, function()
        if card.REMOVED then return Y end
        local st = card.states
        if st and st.dealing then st.dealing.is = N end
        return Y
    end)
end

--- Helper: start visual-only dealing state
local function _start_dealing_visual(gm, to, card, visual_dealing)
    local st = card and card.states
    if not (visual_dealing and st.dealing and to == gm.hand) then return end
    st.dealing.is = Y
    _schedule_clear_dealing(gm, card)
end

--- Helper: set deal waypoint
local function _set_deal_waypoint(card)
    local T       = card.T    
    local base_x  = 4.2*T.w
    local side, lift          = -1, 0.45 + 0.05*rand()
    local sweep, overshoot    = 1.4*rand(), 0.5 + 1.2*rand()
    local tilt, sp_s, dist_s  = 2*(rand() - 0.5), 0.05, 0.1 

    local _mod_x, _mod_y  = base_x + side*(sweep + overshoot)*T.w, T.y - lift*T.h
    local _dx,    _mod_s  = abs(_mod_x - T.x), T.scale*(0.98 + 0.04*rand())
    local speed,  dist    = sp_s*_dx + 0.2*rand(), dist_s*_dx*T.w
    local _t1, _t2        = clamp(( 4 + 2*rand() )/(_dx + 0.001), 0.1, 5), clamp(( 2 + 1*rand() )/(_dx + 0.001), 0.1, 3)

    card.waypoint_T = {     x     = _mod_x,   y           = _mod_y,  w = T.w,  h = T.h, 
        r = T.r + tilt,     scale = _mod_s,   smooth_time = _t1,     max_speed = speed, 
        arrive_dist = dist, landing_smooth_time = _t2, 
        landing_max_speed = 1 + 0.1*rand(),
        pinch_on_arrive = not card.defer_hand_flip and "x",
    }
end

--- Helper: schedule random hand flip
local function _schedule_random_deal_flip(gm, card)
    if not (card and card.defer_hand_flip) then return end

    local delay = 0.2 + 0.7*rand()
    gm.E_MANAGER:enqueue_event({ trigger = "after", delay = delay, blockable = N, blocking = N,
        func = function()
            if card.REMOVED then return Y end
            if card.zone == gm.hand and card.defer_hand_flip and card.sprite_facing == "back" then card.defer_hand_flip = N; card:flip() end
            return Y
        end })
end

--- Helper: _draw card 
local function _draw_card(gm, from, to, card, percent, sort, mute, stay_flipped, vol, discarded_only, visual_dealing)
    local drawn, waypoint_card, gG = nil, nil, gm.GAME;         local Gmod = gG.modifiers
    
    if card then
        if from then card = from:remove_card(card) end
        if card then drawn = Y end
        local stay_flag = N
        if Gmod.flipped_cards and to == gm.hand then if seeded_rand(gm, "flipped_card") < 1/gmod.flipped_cards then stay_flag = Y end end
        card.defer_hand_flip = to:is_hand() and card.sprite_facing == "back" and not stay_flag
        to:emplace(card, stay_flag)
        waypoint_card = card
    else
        waypoint_card = to:draw_card_from(from, stay_flipped, discarded_only)
        if waypoint_card then drawn = Y end
    end

    if waypoint_card then _set_deal_waypoint(waypoint_card) end
    _start_dealing_visual(gm, to, waypoint_card, visual_dealing)
    _schedule_random_deal_flip(gm, waypoint_card)

    if not mute and drawn then
        local Tzone = { gm.deck, gm.hand, gm.play, gm.jokers, gm.consumables, gm.discard }
        if contains(Tzone, from) then gm._vibr = gm._vibr + 0.6 end
        play_clip(gm, "card1", 0.85 + percent*0.2/100, 0.6*(vol or 1))
    end

    if sort then to:sort() end;             return Y
end

--__________________________
--- main: draw from to 
--__________________________
function M.draw_from_to(gm, from, to, percent, dir, sort, card, delay, mute, stay_flipped, vol, discarded_only, visual_dealing)
	local EM, sort, _tb  = gm.E_MANAGER, sort, "before"
    local percent, delay = percent or 50, delay or 0.1;     if dir == "down" then percent = 1 - percent end
	
    EM:enqueue_event({ trigger = _tb, delay = delay, func = function() return _draw_card(gm, from, to, card, percent, sort, mute, stay_flipped, vol, discarded_only, visual_dealing) end })
end

-----------------------------------------------
--- draw deck_2_hand
-----------------------------------------------
--- Helper: top_k_cards 
local function _top_k_cards(zone, k) local cards = {}; for i = 1, k do cards[i] = zone.cards[i] end; return cards end

--- Helper: deal hand in small physical grabs
local function _next_grab_size(remaining) if remaining <= 3 then return remaining end; return min(remaining, rand(3, 5) ) end

---_________________________
--- main: draw deck2hand
---_________________________
function M.draw_deck2hand(gm, e, sort, delay, visual_dealing)
    local hand, deck = gm.hand, gm.deck

	local hand_space = e or min(#deck.cards, hand.config.card_limit - #hand.cards)
    if hand_space <= 0 then return Y end
    local cards = shuffle(_top_k_cards(deck, hand_space))

	sleep(gm, 0.3)
    local i, deal_delay = 1, delay or 0.
    local mute = Y
    while i <= hand_space do
        local grab_size =  _next_grab_size(hand_space - i + 1)
        local grab_pause = deal_delay + 0.001*rand()

        for j = 0, grab_size - 1 do
            local index = i + j
            local card = cards[index]
            local stagger = 0.
            M.draw_from_to(gm, deck, hand, index*100/hand_space, "up", sort, card, stagger, mute, nil, nil, nil, visual_dealing)
        end

        sleep(gm, grab_pause)
        i = i + grab_size
    end
    return Y
end

-----------------------------------------------
--- draw play2discard
-----------------------------------------------
function M.draw_play2discard(gm, e)
    local play, discard, it = gm.play, gm.discard, 1
	local play_count = #play.cards
	for _, v in ipairs(play.cards) do if (not v.shattered) and (not v.destroyed) then M.draw_from_to(gm, play, gm.discard, it*100/play_count, "down", false, v); it = it + 1 end end
end

-----------------------------------------------
--- draw  play2hand 
-----------------------------------------------
function M.draw_play2hand(gm, cards)
	local gold_count = #cards
	for i = 1, gold_count do if not cards[i].shattered and not cards[i].destroyed then M.draw_from_to(gm, gm.play, gm.hand, i*100/gold_count, "up", Y, cards[i]) end end
end

-----------------------------------------------
--- draw  discard2deck
-----------------------------------------------
--- Helper: discard2 deck 
local function _discard2deck(gm)
    local _d = gm.discard;      local discard_count = #_d.cards
    for i = 1, discard_count do M.draw_from_to(gm, _d, gm.deck, i*100/discard_count, "up", nil, nil, 0.005, i % 2 == 0, nil, max((21 - i) / 20, 0.7) ) end
    return Y
end
---_________________________
--- Main: draw discard2deck
---_________________________
function M.draw_discard2deck(gm, e) gm.E_MANAGER:enqueue_event({ func = function() return _discard2deck(gm) end }) end

-----------------------------------------------
--- draw hand2deck 
-----------------------------------------------
function M.draw_hand2deck(gm, e)
    local hand = gm.hand;               local hand_count = #hand.cards
	for i = 1, hand_count do M.draw_from_to(gm, hand, gm.deck, i*100/hand_count, "down", nil, nil, 0.08) end
end

-----------------------------------------------
--- draw hand2discard
-----------------------------------------------
function M.draw_hand2discard(gm, e)
    local hand = gm.hand;           	local hand_count = #hand.cards
	for i = 1, hand_count do M.draw_from_to(gm, hand, gm.discard, i*100/hand_count, "down", nil, nil, 0.07) end
end

return M
