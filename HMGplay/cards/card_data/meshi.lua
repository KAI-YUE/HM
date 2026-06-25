-- Definitions for special meshi cards.

local Y, N = true,false

return {
    egg = {
        base    = { face_style = "meshi", face_art_atlas = "meshi", face_art = "egg_1" },
        options = { suits = { "F" },
            ranks = {
                { rank = "1", value = 1, rank_label = "1", weight = 1 },
            },
        },
        rules = { random_rank = N, random_suit = N },
    },
    egg2 = {
        base    = { face_style = "meshi", face_art_atlas = "meshi", face_art = "egg_2" },
        options = { suits = { "F" },
            ranks = {
                { rank = "1", value = 1, rank_label = "1", weight = 1 },
            },
        },
        rules = { random_rank = N, random_suit = N },
    },
}
