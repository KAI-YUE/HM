local M = {}

function M.tmp_profile()
    local temp_profile = { mem = { deck = "Red Deck", stake = 1 }, stake = 1,
        high_scores = {
        hand          = { label = "Best Hand", amt = 0 },             furthest_round = { label = "Highest Round", amt = 0 },
        furthest_ante = { label = "Highest Ante", amt = 0 },          most_money     = { label = "Most Money", amt = 0 },
        boss_streak   = { label = "Most Bosses in a Row", amt = 0 },  collection     = { label = "Collection", amt = 0, tot = 1},
        win_streak    = { label = "Best Win Streak", amt = 0 },       current_streak = { label = "", amt = 0 },
        poker_hand = { label = "Most Played Hand", amt = 0 } },
    
        career_stats = { c_round_interest_cap_streak = 0,    c_dollars_earned = 0, c_shop_dollars_spent = 0, c_tarots_bought = 0,
        c_planets_bought = 0, c_playing_cards_bought = 0,   c_vouchers_bought = 0, c_tarot_reading_used = 0, c_planetarium_used = 0, 
        c_shop_rerolls   = 0,         c_cards_played = 0,   c_cards_discarded = 0,             c_losses = 0, c_wins             = 0,
        c_rounds         = 0,         c_hands_played = 0, c_face_cards_played = 0,        c_jokers_sold = 0, c_cards_sold       = 0,
        c_single_hand_round_streak = 0 },
        
        progress = {  },  joker_usage = {}, consumable_usage = {}, voucher_usage = {}, hand_usage = {}, deck_usage = {},
        deck_stakes = {}, challenges_unlocked = nil,
        challenge_progress = { completed = {}, unlocked = {} }
    }
    return temp_profile
end

return M