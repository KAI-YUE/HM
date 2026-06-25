-- Definitions for special meshi cards.
local Suits = require("HMGplay.cards.card_data.suits").abbrev
local Ranks = require("HMGplay.cards.card_data.hand_ranks").rank_labels

local Y, N = true,false

return {
    abandoned = {
        base    = { face_style = "machi", face_art_atlas = "machi", face_art = "abandoned1" },
        options = { suits = Suits },
        rules   = { random_rank = Y, random_suit = Y },
    },

    aq = {
        base    = { face_style = "machi", face_art_atlas = "machi", face_art = "aq" },
        options = {  suits = Suits },
        rules   = { random_rank = Y, random_suit = Y },
    },
}
