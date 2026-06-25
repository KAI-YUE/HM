return {
    --- basic settings
    atlas_key = "icons",        keys = { "fork", "knife" },

    --- movement settings
    move_time = 0.18,           settle_speed = 12,
    wobble_rot = 0.08,          bob = 0.05,
    alpha_time = 0.16,
    shadow = { color = { 0, 0, 0, 0.20 }, dist = 1.55 },

    --- positions
    position = { x = -0.25, y = 0.38, h = 0.9 },
    sprites = {
        { key = "fork",  start = { x = 0.15, y = 0, r = -0.62 }, finish = { x = 0.09, y = 0, r = -0.80 } },
        { key = "knife", flip_x = true, start = { x =  0.09, y = 0, r =  0.62 }, finish = { x =  0.15, y = 0, r =  0.80 } },
    },
}
