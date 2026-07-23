local FileIO = require("core.io.fileio")

local M = {}

------------------------------------------
--- Unlock card 
------------------------------------------
function M.unlock(gm, card)
	if card.unlocked then return true end
    
    local game, Fs, Pool = gm.GAME, gm.Fs, gm.P_CPools
    if game.seeded or game.challenge then return end
    
    gm:save_notify(card);       card.unlocked = true
    
    if card.set == "Deck" then Fs.register_card_discovery(gm, card) end    -- Special case: unlocking a deck back also discovers it
    table.sort(Pool["Deck"], function(a, b) return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0)) end)
    gm:save_progress(true)                                      -- Keep card pools ordered by unlock state
    Fs.enqueue_alert(gm, card.key, card.set)
    return true
end

---------------------------------------------
--- Increment Challenge_unlock 
---------------------------------------------
function M.inc_challenge_unlock(gm)
    local P, SET, Fs        = gm.g_profile, gm.SET, gm.Fs
	local Ch, prof          = gm.CHALLENGES, P[SET.profile]
    local _alert, deck_wins = Fs.enqueue_alert, 0
	if prof.all_unlocked then return end

	if prof.challenges_unlocked then  -- challenge unlock 
		local _ch_comp, _ch_tot = 0, #Ch
		for _, v in ipairs(Ch) do
            if not v.id then goto continue end
			if not prof.challenge_progress.completed[v.id] then goto continue end
            _ch_comp = _ch_comp + 1
			::continue::
		end
		prof.challenges_unlocked = math.min(_ch_tot, _ch_comp + 5)
        return
    end

    for _, v in pairs(prof.deck_usage) do     -- Increment the deck wins <for statistics>
        if not v.wins or not v.wins[1] then goto continue end
        deck_wins = deck_wins + 1
        ::continue::
    end
    if deck_wins < gm.c_wins then return end 
    prof.challenges_unlocked = 5
    _alert(gm, "b_challenge", "Deck")
end

----------------------------------------------
--- Toast Unlock notification 
----------------------------------------------
function M.toast_unlock_notification(gm)
    local SET, EM = gm.SET, gm.E_MANAGER
    
    local function _pickle_load_notify()
        local _UN
        if gm.shared_save_path then
            local S = FileIO.unpickle(gm:shared_save_path())
            _UN = S and S.unlock_notify and S.unlock_notify[SET.profile]
            if _UN then S.unlock_notify[SET.profile] = nil; FileIO.pickle_dump(gm:shared_save_path(), S) end
        end
        _UN = _UN or get_compressed(SET.profile.."/".."unlock_notify.hm")
        if not _UN then return true end 
        for key in string.gmatch(_UN .. "\n", "(.-)\n") do create_unlock_overlay(key) end
        love.filesystem.remove(SET.profile.."/".."unlock_notify.hm")
        return true
    end

    EM:enqueue_event({ func = function() return _pickle_load_notify() end })
end

--------------------------------------------------------
--- Handle unlock request
--------------------------------------------------------
--- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
--- Helper funcs to handle different unlock achievements
--- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
-- Helper: challenge finish achievements
local function _win_challenge(gm, P, SET, _achm)
    _achm(gm, "rule_bender")
    local comp, all_done = P[SET.profile].challenge_progress.completed, true
    for _, v in pairs(gm.CHALLENGES) do if not comp[v.id] then all_done = false; break end end
    if not all_done then return end
    _achm(gm, "rule_breaker")
end

-- Helper: career_stat achievements
local function _career_stat(gm, _achm, P, SET, name)
    local career_stats = P[SET.profile].career_stats[name]
    if name == "c_cards_played"    and career_stats >= 2500 then _achm(gm, "card_player");    return end
    if name == "c_cards_discarded" and career_stats >= 2500 then _achm(gm, "card_discarder"); return end
end

-- Helper: ante related achievements
local function _ante_up(gm, ante, _achm)
    if ante >= 4  then _achm(gm, "ante_up")     end
	if ante >= 8  then _achm(gm, "ante_upper")  end
end

-- Helper: win related achievements
local function _win(gm, _achm, game)
    _achm(gm, "heads_up")
    if game.round <= 12 then _achm(gm, "speedrunner") end
    if game.round_scores.times_rerolled.amt <= 0 then _achm(gm, "you_get_what_you_get") end
end

-- Helper: win stake related achievements 
local function _win_stake(gm, _achm)
    local Pro = gm.PROGRESS
    local highest_win = gm.Fs.deck_max_win_stake(gm, nil) or 0

    local win_achms = { ["2"]="low_stakes", ["4"]="mid_stakes", ["8"]="high_stakes"}
    for k, v in pairs(win_achms) do if highest_win >= tonumber(k) then _achm(gm, v) end end

    if not Pro then return end -- early bail out

    local dstakes, jstickers = Pro.deck_stakes, Pro.joker_stickers
    if dstakes.tally/dstakes.of >= 1     then _achm(gm, "completionist_plus") end
    if jstickers.tally/jstickers.of >= 1 then _achm(gm, "completionist_plus_plus") end
end

-- Helper: money achievements
local function _money(gm, _achm) if gm.GAME.dollars >= 400 then _achm(gm, "nest_egg") end end

-- Helper: hand achievements
local function _hand(gm, args, _achm)
    local sh = args.scoring_hand
    if args.disp_text == "Royal Flush" then _achm(gm, "royale") end
    if args.handname ~= "Flush" or not sh then return end -- no more achievements
    local wilds = 0
    for _, c in ipairs(sh) do if c.ability.name == "Wild Card" then wilds = wilds + 1 end end
    if wilds == #sh then _achm(gm, "flushed") end
end

-- Helper: shatter achievements
local function _shatter(gm, _achm, shattered) if shattered and #shattered >= 2 then _achm(gm, "shattered") end end

-- Helper: redeem achievements
local function _redeem(gm, _achm)
    local game = gm.GAME
    local vcount = - (game.starting_voucher_count or 0)
    for _ in pairs(game.used_vouchers) do vcount = vcount + 1 end
    if vcount < 5 or game.round_resets.ante > 4 then return end 
    _achm(gm, "roi")
end

-- Helper: upgrade_hand achievements
local function _upgrade_hand(gm, _achm, level) if level >= 10 then _achm(gm, "retrograde") end end

-- Helper: chip achievements
local function _chip(gm, _achm, chips)
    if chips >= 1e4  then _achm(gm, "_10k")     end
	if chips >= 1e6  then _achm(gm, "_1000k")   end
	if chips >= 1e8  then _achm(gm, "_100000k") end
end

-- Helper: modify_deck achievements
local function _modify_deck(gm, _achm, deck)
    if not deck then return end 
    local card_limit = deck.config.card_limit
    if card_limit <= 20 then _achm(gm, "tiny_hands") end
	if card_limit >= 80 then _achm(gm, "big_hands")  end
end

-- Helper: Discovery amount achievements
local function _discover_amount(gm, _achm)
    local dt         = gm.DISCOVER_TALLIES
    local check_list = { "vouchers", "spectrals", "tarots", "planets", "total" }
    local achms      = { "extreme_couponer", "clairvoyance", "cartomancy", "astronomy", "completionist"}
    for i, v in ipairs(check_list) do if dt[v].tally / dt[v].of >= 1 then _achm(gm, achms[i]) end end
end

-- **************************************************
--------------------------------------------------
-- Handle an unlock event 
--------------------------------------------------
--- Helper
local function c_hand(hname, extra, unlock, gm, card)
    if hname ~= extra then return false end
    return unlock(gm, card)
end
--- Helper
local function c_career_stat(hname, utype, st, extra, unlock, gm, card)
    if hname ~= utype    then return false end 
    if st < extra        then return false end
    return unlock(gm, card)
end
-- Helper
local function c_min_hand_size(hand, extra, unlock, gm, card)
    if not hand then return false end
    if hand.config.card_limit > extra then return false end
    return unlock(gm, card)
end
-- Helper
local function c_interest_streak(extra, stats, unlock, gm, card)
    if extra > stats.c_round_interest_cap_streak then return false end
    return unlock(gm, card)
end
-- Helper
local function c_card_replay(pc, extra, unlock, gm, card)
    for _, v in ipairs(pc) do
        local played = v.base.times_played
        if played >= extra then return unlock(gm, card) end
    end
    return false
end

--- Helper
local function c_all_hearts(unlock, gm, card)
    local played = true
    for _, v in ipairs(gm.deck.cards) do
        local name, suit = v.ability.name, v.base.suit
        if name ~= "Stone Card" and suit == "heart" then played = false end
    end
    for _, v in ipairs(gm.hand.cards) do
        local name, suit = v.ability.name, v.base.suit
        if name ~= "Stone Card" and suit == "heart" then played = false end
    end
    if played then return unlock(gm, card) end
    return false
end

--- Helper
local function c_redeem(extra, unlock, gm, card)
    local redeemed = #gm.GAME.used_vouchers 
    if redeemed >= extra then return unlock(gm, card) end
    return false
end
-- Helper
local function c_edition(extra, unlock, gm, card)
    local j = gm.jokers
    if j then return false end
    local shiny = 0
    for _, v in ipairs(j.cards) do if v.edition then shiny = shiny + 1 end end
    if shiny >= extra then return unlock(gm, card) end
    return false
end
-- Helper
local function c_double_gold(unlock, gm, card)   return unlock(gm, card) end
local function c_continue_game(unlock, gm, card) return unlock(gm, card) end
-- Helper
local function c_blank_redeem(extra, unlock, gm, card)
    local P, SET = gm.g_profile, gm.SET
    local vu = P[SET.profile].voucher_usage["v_blank"]
    if vu and vu.count >= extra then return unlock(gm, card) end
    return false
end
-- Helper
local function c_modify_deck(extra, pc, unlock, gm, card)
    if not extra then return false end
    if extra.suit then
        local count = 0
        for _, v in pairs(pc) do if v.base.suit == extra.suit then count = count + 1 end end
        if count >= extra.count then return unlock(gm, card) end
    end
    if extra.enhancement then
        local count = 0
        for _, v in pairs(pc) do if v.ability.name == extra.enhancement then count = count + 1 end end
        if count >= extra.count then return unlock(gm, card) end
    end
    if extra.tally then
        local count = 0
        for _, v in pairs(pc) do if v.ability.set == "Enhanced" then count = count + 1 end end
        if count >= extra.count then return unlock(gm, card) end
    end
    return false
end
-- Helper 
local function c_discover_amount(cond, args, unlock, gm, card)
    if cond.amount       and cond.amount <= args.amount             then return unlock(gm, card) end
    if cond.tarot_count  and cond.tarot_count <= args.tarot_count   then return unlock(gm, card) end
    if cond.planet_count and cond.planet_count <= args.planet_count then return unlock(gm, card) end
    return false
end
-- Helper 
local function c_win_deck(cond, unlock, gm, card)
    local deck = cond.deck
    if not deck then return false end
    local d_stake = gm.Fs.deck_max_win_stake
    if d_stake(gm, deck) > 0 then return unlock(gm, card) end    
    return false
end
-- Helper
local function c_win_stake(cond, unlock, gm, card)
    if not cond.stake then return false end
    local d_stake = gm.Fs.deck_max_win_stake
    if d_stake(gm) >= cond.stake then return unlock(gm, card) end
    return false
end
-- Helper 
local function c_discover_planets(unlock, gm, card)
    local count = 0
    for _, v in pairs(gm.CMod) do if v.set == "Planet" and v.discovered then count = count + 1 end end
    if count >= 9 then return unlock(gm, card) end
    return false
end
-- Helper 
local function c_blind_discoveries(extra, unlock, gm, card)
    local discovered = 0
    for _, v in pairs(gm.P_BLINDS) do if v.discovered then discovered = discovered + 1 end end
    if discovered >= extra then return unlock(gm, card) end
    return false
end
-- Helper 
local function c_modify_jokers(extra, unlock, gm, card)
    local j = gm.jokers
    if not j then return false end 
    if not extra or not extra.count then return false end
    local count = 0
    for _, v in pairs(j.cards) do
        if v.ability.set ~= "Joker" then goto continue end  
        if not v.edition or not v.edition.polychrome then goto continue end
        if not extra.polychrome then goto continue end
        count = count + 1
        ::continue::
    end
    if count >= extra.count then return unlock(gm, card) end
end
-- Helper 
local function c_money(extra, unlock, gm, card)
    local game = gm.GAME
    if extra <= game.dollars then return unlock(gm, card) end
    return false
end
-- Helper
local function c_round_win(extra, unlock, gm, card)
    local P, SET = gm.g_profile, gm.SET
    local game, name = gm.GAME, card.name

    if name == "Matador" then
        local cround = game.current_round
        if cround.hands_played ~= 1 then return false end
        if cround.discards_left ~= game.round_resets.discards then return false end
        if game.blind:get_type() ~= "Boss" then return false end
        return unlock(gm, card)
    end
    if name == "Troubadour" then
        local streak = P[SET.profile].career_stats.c_single_hand_round_streak
        if streak >= extra then return unlock(gm, card) end
    end
    if name == "Hanging Chad" then
        if game.last_hand_played ~= extra  then return false end
        if game.blind:get_type() ~= "Boss" then return false end
        return unlock(gm, card)
    end
    return false
end
-- Helper
local function c_ante_up(cond, args, unlock, gm, card)
    if not cond.ante then return false end
    if args.ante ~= cond.ante then return unlock(gm, card) end
    return false
end
-- Helper
local function c_hand_contents(cards, unlock, gm, card)
    local name = card.name
    if name == "Seeing Double" then
        local tally = 0
        for _, c in ipairs(cards) do if c:get_id() == 7 and c:is_suit("club") then tally = tally + 1 end end
        if tally >= 4 then return unlock(gm, card) end
    end
    if name == "Golden Ticket" then
        local tally = 0
        for _, c in ipairs(cards) do if c.ability.name == "Gold Card" then tally = tally + 1 end end
        if tally >= 5 then return unlock(gm, card) end
    end
    return false
end

-- Helper 
local function c_discard_custom(cards, unlock, gm, card)
    local name, _eva_hand = card.name, gm.Fs.evaluate_hand
    return false
end

-- Helper 
local function c_win_no_hand(extra, unlock, gm, card)
    if gm.GAME.hands[extra].played ~= 0 then return false end
    return unlock(gm, card)
end

-- Helper
local function c_win_custom(unlock, gm, card)
    local game, name = gm.GAME, card.name
    if name == "Invisible Joker" and game.max_jokers <= 4 then return unlock(gm, card) end
    if name == "Blueprint" then return unlock(gm, card) end
    return false
end
-- Helper
local function c_win(cond, unlock, gm, card)
    local game = gm.GAME
    if cond.n_rounds >= game.round then return unlock(gm, card) end
    return false
end
-- Helper 
local function c_chip_score(cond, args, unlock, gm, card)
    if cond.chips > args.chips then return false end
    return unlock(gm, card)
end

--- Helper: handle_content unlock
local function _handle_content_unlock(gm, args, _t, card)
    local P, SET, pc, sn       = gm.g_profile, gm.SET, gm.run_card_id, args.statname
    local unlock, cond, hname  = M.unlock, card.unlock_condition, args.handname
    local utype, extra, stats  = cond.type, cond.extra, P[SET.profile].career_stats
    
    if _t == "career_stat"           then return c_career_stat(hname, utype, stats[sn], extra, unlock, gm, card) end
    -- -- type-specific checks
    if utype ~= _t                   then return false end
    if     _t == "hand"              then return c_hand(hname, extra, unlock, gm, card)
    elseif _t == "min_hand_size"     then return c_min_hand_size(hand, extra, unlock, gm, card) 
    elseif _t == "interest_streak"   then return c_interest_streak(extra, stats, unlock, gm, card)
    elseif _t == "run_card_replays"  then return c_card_replay(pc, extra, unlock, gm, card)
    elseif _t == "play_all_hearts"   then return c_all_hearts(unlock, gm, card) 
    elseif _t == "run_redeem"        then return c_redeem(extra, unlock, gm, card)
    elseif _t == "have_edition"      then return c_edition(extra, unlock, gm, card)
    elseif _t == "double_gold"       then return c_double_gold(unlock, gm, card) 
    elseif _t == "continue_game"     then return c_continue_game(unlock, gm, card)
    elseif _t == "blank_redeems"     then return c_blank_redeem(extra, unlock, gm, card)
    elseif _t == "modify_deck"       then return c_modify_deck(extra, pc, unlock, gm, card) 
    elseif _t == "discover_amount"   then return c_discover_amount(cond, args, unlock, gm, card)
    elseif _t == "win_deck"          then return c_win_deck(cond, unlock, gm, card) 
    elseif _t == "win_stake"         then return c_win_stake(cond, unlock, gm, card) 
    elseif _t == "discover_planets"  then return c_discover_planets(unlock, gm, card)
    elseif _t == "blind_discoveries" then return c_blind_discoveries(extra, unlock, gm, card) 
    elseif _t == "modify_jokers"     then return c_modify_jokers(extra, unlock, gm, card)
    elseif _t == "money"             then return c_money(extra, unlock, gm, card)
    elseif _t == "round_win"         then return c_round_win(extra, unlock, gm, card)
    elseif _t == "ante_up"           then return c_ante_up(cond, args, unlock, gm, card)
    elseif _t == "hand_contents"     then return c_hand_contents(args.cards, unlock, gm, card)
    elseif _t == "discard_custom"    then return c_discard_custom(args.cards, unlock, gm, card) 
    elseif _t == "win_no_hand"       then return c_win_no_hand(extra, unlock, gm, card) 
    elseif _t == "win_custom"        then return c_win_custom(unlock, gm, card)
    elseif _t == "win"               then return c_win(cond, unlock, gm, card)
    elseif _t == "chip_score"        then return c_chip_score(cond, args, unlock, gm, card) end
    return false
end

--_________________________________________
--- main: unlock request
--_________________________________________
function M.handle_unlock_request(gm, args)
	if not args or not next(args) then return end
    local game = gm.GAME
	if game.seeded then return end

    local _t, Fs, P, SET    = args.type, gm.Fs, gm.g_profile, gm.SET
    local _achm             = Fs.grant_achievements
	
    -- Achievements related
    if _t == "win_challenge"        then _win_challenge(gm, P, SET, _achm) end
	if game.challenge               then return end          -- no unlocks during challenge
	if     _t == "career_stat"      then _career_stat(gm, _achm, P, SET, args.statname)
	elseif _t == "ante_up"          then _ante_up(gm, args.ante, _achm)
    elseif _t == "win"              then _win(gm, _achm, game)
    elseif _t == "win_stake"        then _win_stake(gm, _achm)
    elseif _t == "money"            then _money(gm, _achm)
    elseif _t == "hand"             then _hand(gm, args, _achm)
    elseif _t == "shatter"          then _shatter(gm, _achm, args.shattered)
    elseif _t == "run_redeem"       then _redeem(gm, _achm)
	elseif _t == "upgrade_hand"     then _upgrade_hand(gm, _achm, args.level)
    elseif _t == "chip_score"       then _chip(gm, _achm, args.chips)
    elseif _t == "modify_deck"      then _modify_deck(gm, _achm, gm.deck)
    elseif _t == "spawn_legendary"  then _achm(gm, "legendary")
	elseif _t == "discover_amount"  then _discover_amount(gm, _achm) end

    -- Update P_locked pools
    local i = 1
    while i <= #gm.P_locked do
        local card, granted = gm.P_locked[i], false
        local unlocked, cond = card.unlocked, card.unlock_condition
		if not unlocked and cond then granted = _handle_content_unlock(gm, args, _t, card) end
        if granted then table.remove(gm.P_locked, i) 
        else i = i + 1 end
    end
end

return M
