local hlist, hrank   = require("HMGplay.cards.card_data.hand_list"), require("HMGplay.cards.card_data.hand_ranks")
local I18N           = require("HMfns.utils.format.i18n_utils")

local i18n = I18N.i18n
local format         = string.format
local push, NoR      = table.insert, hrank.num_ranks
local Y, N, max_play = true, false, 5

local M = {}

--------------------------------------------------------
--- Helpers: optional evaluator params
--------------------------------------------------------
local function _max_play(opts) return opts and opts.max_play or max_play end

local function _fetch_joker(gm, name, opts)
    if opts and opts.ignore_jokers then return N end
    if type(_joker) ~= "function" then return N end
    return next(_joker(gm, name)) and Y or N
end

local function _flush_suits(opts)
    return opts and opts.suits or { "spade", "heart", "club", "diamond" }
end

--------------------------------------------------------
--- Fetch flush
--------------------------------------------------------
function M.fetch_flush(gm, hand, opts)
	local ret, suits   = {}, _flush_suits(opts)
	local target       = _max_play(opts)
	local four_fingers = _fetch_joker(gm, "Four Fingers", opts)
	local offset       = (four_fingers and 1 or 0)

	if #hand > target or #hand < (target - offset) then return ret end
    for j = 1, #suits do
        local t, suit, flush_count = {}, suits[j], 0
        for i = 1, #hand do if hand[i]:is_suit(suit, nil, Y) then flush_count = flush_count + 1; push(t, hand[i]) end end
        if flush_count >= (target - offset) then push(ret, t); return ret end
    end
    return ret
end

--------------------------------------------------------------
--- Fetch straight
--------------------------------------------------------------
function M.fetch_straight(gm, hand, opts)
	local ret, t, cards  = {}, {}, {}
	local target         = _max_play(opts)
	local four_fingers   = _fetch_joker(gm, "Four Fingers", opts)
    local offset, st_len = (four_fingers and 1 or 0), 0
    local NoH, lbound    = #hand, target - offset

	if NoH > target or NoH < lbound then return ret end
    for i = 1, NoH do
        local r = hand[i]:get_id()
        if r > 1 and r <= NoR then if cards[r] then push(cards[r], hand[i]); else cards[r] = { hand[i] } end end
    end

    local straight, can_skip, skipped = N, _fetch_joker(gm, "Shortcut", opts), N
    for j = 1, NoR do
        local k = (j == 1 and NoR or j)
        if cards[k] then st_len, skipped = st_len + 1, N; for _, v in ipairs(cards[k]) do push(t, v) end
        elseif can_skip and not skipped and j ~= NoR then skipped = Y
        else  st_len, skipped = 0, N; if not straight then t = {} else break end end
        if st_len >= lbound then straight = Y end
    end

    if not straight then return ret end
    push(ret, t);        return ret
end

-----------------------------------------------------------
--- Fetch highest
-----------------------------------------------------------
function M.fetch_highest(gm, hand)
	local h
	for _, v in ipairs(hand) do if v and (not h or v:get_nominal() > h:get_nominal()) then h = v end end
	if h then return {{ h }} end
	return {}
end

---------------------------------------------------------
--- Fetch N-of-Akind
--------------------------------------------------------- 
function M.fetch_N_of_Akind(gm, num, hand)
    local vals, ret = {}, {} 
    if num <= 1 then return ret end 
    for i = 1, NoR do push(vals, {}) end
	for i = #hand, 1, -1 do
		local curr, rank = { hand[i] }, hand[i]:get_id()
		for j = 1, #hand do if rank == hand[j]:get_id() and i ~= j then push(curr, hand[j]) end end
        if #curr == num then vals[curr[1]:get_id()] = curr; if num == #hand then break end end
	end
	for i = NoR, 1, -1 do if next(vals[i]) then push(ret, vals[i]) end end
	return ret
end

-----------------------------------------------------------------
--- Evaluate hand
-----------------------------------------------------------------
--- Helper: build the hand result 
local function _hand(results, parts, key, hname)
    results[hname] = parts[key]
    if not results.top then results.top = results[hname] end
end

-- Helper: handle straight flush 
local function _straight_flush(results, parts)
    local _s, _f, ret = parts._straight, parts._flush, {}
    for _, v in ipairs(_f[1]) do push(ret, v) end
    for _, v in ipairs(_s[1]) do
        local in_straight = nil
        for _, vv in ipairs(_f[1]) do if vv == v then in_straight = true end end
        if not in_straight then push(ret, v) end
    end
    results["Straight Flush"] = { ret }
    if not results.top then results.top = results["Straight Flush"] end   
end

-- Helper: handle full house 
local function _full_house(results, parts, hname)
    local hand, hname = {}, hname or "Full House"
    local fh_3, fh_2 = parts._3[1], parts._2[1]
    for i=1, #fh_3 do push(hand, fh_3[i]) end
    for i=1, #fh_2 do push(hand, fh_2[i]) end
    push(results[hname], hand)
    if not results.top then results.top = results[hname] end
end

-- Helper: handle 2 pairs 
local function _two_pairs(results, parts)
    local hand, r   = {}, parts._2
    local fh_2a, fh_2b = r[1], r[2]
    if not fh_2b then fh_2b = parts._3[1] end
    for i = 1, #fh_2a do push(hand, fh_2a[i]) end
    for i = 1, #fh_2b do push(hand, fh_2b[i]) end
    push(results["Two Pair"], hand)
    if not results.top then results.top = results["Two Pair"] end
end

--_____________________________________________
--- Main: evaluate hand 
--_____________________________________________
function M.evaluate_hand(gm, hand, opts)
    local fn_list = { ["_flush"] = M.fetch_flush, ["_straight"] = M.fetch_straight, ["_highest"] = M.fetch_highest }
    local results, parts = { top = nil }, {}
    
    for _, hname in ipairs(hlist) do results[hname] = {} end            -- initialize results
    for i = 2, 5 do parts[format("_%d", i)] = M.fetch_N_of_Akind(gm, i, hand) end   -- initialize parts: how many same cards  
    for k, v in pairs(fn_list) do parts[k] = v(gm, hand, opts) end      -- continue: special hands

    local is_five, is_four, is_three = next(parts._5), next(parts._4), next(parts._3)
    local is_fh,   is_flush, is_st   = next(parts._3) and next(parts._2), next(parts._flush), next(parts._straight)
    local is_2pair, is_pair, is_h    = (#parts._2 == 2) or is_fh, next(parts._2), next(parts._highest)

	if is_five and is_flush then _hand(results, parts, "_5", "Flush Five") end
    if is_fh   and is_flush then _full_house(results, parts, "Flush House") end
	if is_five              then _hand(results, parts, "_5", "Five of a Kind") end
	if is_st   and is_flush then _straight_flush(results, parts) end
	if is_four              then _hand(results, parts, "_4", "Four of a Kind") end
    if is_fh                then _full_house(results, parts) end
	if is_flush             then _hand(results, parts, "_flush", "Flush") end
    if is_st                then _hand(results, parts, "_straight", "Straight") end
	if is_three             then _hand(results, parts, "_3", "Three of a Kind") end
    if is_2pair             then _two_pairs(results, parts) end
	if is_pair              then _hand(results, parts, "_2", "Pair") end
    if is_h                 then _hand(results, parts, "_highest", "High Card") end

    local r_five,  r_four = results["Five of a Kind"],  results["Four of a Kind"]
    local r_three, r_pair = results["Three of a Kind"], results["Pair"]
    if next(r_five)  then for i = 1, 4 do push(r_four, r_five[i])  end end
	if next(r_four)  then for i = 1, 3 do push(r_three, r_four[i]) end end
	if next(r_three) then for i = 1, 2 do push(r_pair, r_three[i]) end end 
	return results
end

---------------------------------------------------
--- Poker hand info 
---------------------------------------------------
function M.poker_hand_info(gm, _cards, opts)
	local poker_hands, scoring_hand      = M.evaluate_hand(gm, _cards, opts), {}
	local text, disp_text, loc_disp_text = "NULL", "NULL", "NULL"

	if     next(poker_hands["Flush Five"])      then text, scoring_hand = "Flush Five",     poker_hands["Flush Five"][1]
	elseif next(poker_hands["Flush House"])     then text, scoring_hand = "Flush House",    poker_hands["Flush House"][1]
	elseif next(poker_hands["Five of a Kind"])  then text, scoring_hand = "Five of a Kind", poker_hands["Five of a Kind"][1]
	elseif next(poker_hands["Straight Flush"])  then text, scoring_hand = "Straight Flush", poker_hands["Straight Flush"][1]
	elseif next(poker_hands["Four of a Kind"])  then text, scoring_hand = "Four of a Kind", poker_hands["Four of a Kind"][1]
	elseif next(poker_hands["Full House"])      then text, scoring_hand = "Full House",     poker_hands["Full House"][1]
	elseif next(poker_hands["Flush"])           then text, scoring_hand = "Flush",          poker_hands["Flush"][1]
	elseif next(poker_hands["Straight"])        then text, scoring_hand = "Straight",       poker_hands["Straight"][1]
	elseif next(poker_hands["Three of a Kind"]) then text, scoring_hand = "Three of a Kind", poker_hands["Three of a Kind"][1]
	elseif next(poker_hands["Two Pair"])        then text, scoring_hand = "Two Pair",        poker_hands["Two Pair"][1]
	elseif next(poker_hands["Pair"])            then text, scoring_hand = "Pair",            poker_hands["Pair"][1]
	elseif next(poker_hands["High Card"])       then text, scoring_hand = "High Card",       poker_hands["High Card"][1] end

	disp_text = text
	if text == "Straight Flush" then
		local min_id = 10
		for j = 1, #scoring_hand do if scoring_hand[j]:get_id() < min_id then min_id = scoring_hand[j]:get_id() end end
		if min_id >= 10 then disp_text = "Royal Flush" end
	end

	loc_disp_text = i18n(gm, disp_text, "poker_hands")
	return text, loc_disp_text, poker_hands, scoring_hand, disp_text
end

return M
