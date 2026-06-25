local Y, N = true, false

return function (GMgr)
-----------------------------
--- init_game_manager
----------------------------------
function GMgr:init_game_manager()
    local bosses_used, GAME = {}, { won = N }
    
    local _tab   = { "hand_usage", "modifiers", "banned_keys", "pseudorandom", "cards_played", "tags", "pool_flags", }
    local _list  = { "last_tarot_planet", "blind", "blind_on_deck" }
    local _dict  = { round = 0,  starting_deck_size = 52,  dollars  = 0,  inflation = 0, 
        bankrupt_at = 0,         discount_percent   = 0}
    
    for _, _t in ipairs(_tab)   do GAME[_t] = {} end 
    for _, v  in ipairs(_list)  do GAME[v] = nil end
    for k, v  in pairs(_dict)   do GAME[k] = v end 

    GAME.pseudorandom.seed = _SEED -- for now use the global config seed 

    local round_scores = {
        furthest_ante  = { label = "Ante",  amt = 0},             furthest_round  = { label = "Round", amt = 0},             hand            = { label = "Best Hand", amt = 0 },
        poker_hand     = { label = "Most Played Hand", amt = 0 }, new_collection  = { label = "New Discoveries", amt = 0 },  times_rerolled  = { label = "Times Rerolled", amt = 0 },
        cards_played   = { label = "Cards Played", amt = 0 },     cards_discarded = { label = "Cards Discarded", amt = 0 },  cards_purchased = { label = "Cards Purchased", amt = 0 } }
    
    local hands = {
        ["Flush Five"]      = { visible = N, order = 1,  mult = 16,  chips = 160, s_mult = 16,  s_chips = 160, level = 1, l_mult = 3, l_chips = 50, played = 0, played_this_round = 0, example = { {"S_A", Y }, {"S_A", Y }, {"S_A", Y }, {"S_A", Y }, {"S_A", Y } }},
        ["Flush House"]     = { visible = N, order = 2,  mult = 14,  chips = 140, s_mult = 14,  s_chips = 140, level = 1, l_mult = 4, l_chips = 40, played = 0, played_this_round = 0, example = { {"D_7", Y }, {"D_7", Y }, {"D_7", Y }, {"D_4", Y }, {"D_4", Y } }},
        ["Five of a Kind"]  = { visible = N, order = 3,  mult = 12,  chips = 120, s_mult = 12,  s_chips = 120, level = 1, l_mult = 3, l_chips = 35, played = 0, played_this_round = 0, example = { {"S_A", Y }, {"H_A", Y }, {"H_A", Y }, {"C_A", Y }, {"D_A", Y } }},
        ["Straight Flush"]  = { visible = Y, order = 4,  mult = 8,   chips = 100, s_mult = 8,   s_chips = 100, level = 1, l_mult = 4, l_chips = 40, played = 0, played_this_round = 0, example = { {"S_Q", Y }, {"S_J", Y }, {"S_T", Y }, {"S_9", Y }, {"S_8", Y } }},
        ["Four of a Kind"]  = { visible = Y, order = 5,  mult = 7,   chips = 60,  s_mult = 7,   s_chips = 60,  level = 1, l_mult = 3, l_chips = 30, played = 0, played_this_round = 0, example = { {"S_J", Y }, {"H_J", Y }, {"C_J", Y }, {"D_J", Y }, {"C_3", N } }},
        ["Full House"]      = { visible = Y, order = 6,  mult = 4,   chips = 40,  s_mult = 4,   s_chips = 40,  level = 1, l_mult = 2, l_chips = 25, played = 0, played_this_round = 0, example = { {"H_K", Y }, {"C_K", Y }, {"D_K", Y }, {"S_2", Y }, {"D_2", Y } }},
        ["Flush"]           = { visible = Y, order = 7,  mult = 4,   chips = 35,  s_mult = 4,   s_chips = 35,  level = 1, l_mult = 2, l_chips = 15, played = 0, played_this_round = 0, example = { {"H_A", Y }, {"H_K", Y }, {"H_T", Y }, {"H_5", Y }, {"H_4", Y } }},
        ["Straight"]        = { visible = Y, order = 8,  mult = 4,   chips = 30,  s_mult = 4,   s_chips = 30,  level = 1, l_mult = 3, l_chips = 30, played = 0, played_this_round = 0, example = { {"D_J", Y }, {"C_T", Y }, {"C_9", Y }, {"S_8", Y }, {"H_7", Y } }},
        ["Three of a Kind"] = { visible = Y, order = 9,  mult = 3,   chips = 30,  s_mult = 3,   s_chips = 30,  level = 1, l_mult = 2, l_chips = 20, played = 0, played_this_round = 0, example = { {"S_T", Y }, {"C_T", Y }, {"D_T", Y }, {"H_6", N }, {"D_5", N } }},
        ["Two Pair"]        = { visible = Y, order = 10, mult = 2,   chips = 20,  s_mult = 2,   s_chips = 20,  level = 1, l_mult = 1, l_chips = 20, played = 0, played_this_round = 0, example = { {"H_A", Y }, {"D_A", Y }, {"C_Q", N }, {"H_4", Y }, {"C_4", Y } }},
        ["Pair"]            = { visible = Y, order = 11, mult = 2,   chips = 10,  s_mult = 2,   s_chips = 10,  level = 1, l_mult = 1, l_chips = 15, played = 0, played_this_round = 0, example = { {"S_K", N }, {"S_9", Y }, {"D_9", Y }, {"H_6", N }, {"D_3", N } }},
        ["High Card"]       = { visible = Y, order = 12, mult = 1,   chips = 5,   s_mult = 1,   s_chips = 5,   level = 1, l_mult = 1, l_chips = 10, played = 0, played_this_round = 0, example = { {"S_A", Y }, {"D_Q", N }, {"D_9", N }, {"C_4", N }, {"D_3", N } }},
    }

    GAME["starting_params"] = self.Fs.init_gameplay_params()      -- Ad-hoc tables 
    GAME["probabilities"]   = { normal = 1 };                     GAME["bosses_used"]   = bosses_used                    
    GAME["previous_round"]  = { dollars = 4 };                    
    GAME["round_scores"]    = round_scores;                       
    GAME["round_bonus"]     = { next_hands = 0, discards = 0 };   GAME["shop"] =  { joker_max = 2 }
    GAME["hands"]           = hands

    self.GAME = GAME
end

end 