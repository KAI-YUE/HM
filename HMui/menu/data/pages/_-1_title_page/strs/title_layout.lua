local C = require("HMfns.animate.color.color_const")

local CUI,  CT  = C.UI,    C.TITLE
local ccrm, ck  = C.CREAM, C.BLACK
local ctd,  cw  = CUI.TEXT_DARK, C.WHITE
local cpaper    = CT.PAPER

local Y, N = true, false

local M = {}

--- manual_enter = Y means those decorators are opted out of the generic page-switch entrance

M.kanji = {
    --- Kanji Hen
    { id = "hen",   mask = "_jp1_hen_mask",   kanji = "_jp1_hen_kanji",   x = 0.8,  y = 0.80, mask_x_bias = 0.70,  mask_y_bias = 0.05, kanji_x_bias = 0.50, kanji_y_bias = 0.16, mask_w = 4.91, kanji_w = 3.60, r = 0.0,
        decorators = {
            --- chef_hat
            { id = "chef_hat_mask", atlas = "icon_pack", key = "chef_hat_mask", stage = "title", x_bias = 2.00, y_bias = -0.60, w = 1.58, r =  -0.1, tint = cpaper, dist = 2.5, shadow_layer = 10,  face_layer = 19, manual_enter = Y, paint = { shader = "paper_sway", speed = 0.5 } },
            { id = "chef_hat_pad",  atlas = "icon_pack", key = "chef_hat_mask", stage = "title", x_bias = 2.20, y_bias = -0.26, w = 1.1, r =  -0.,   tint = cpaper, dist = 2.5, shadow_layer = 10,  face_layer = 30, manual_enter = Y,  shadow = N },
            { id = "chef_hat",      atlas = "icon_pack", key = "chef_hat",      stage = "title", x_bias = 2.20, y_bias = -0.565, w = 1.22, r =  -0.1, tint = ctd,    dist = 0,   shadow_layer = 10, face_layer = 30, manual_enter = Y, shadow = N },
        },
    },

    --- Kanji Shin
    { id = "shin",  mask = "_jp2_shin_mask",  kanji = "_jp2_shin_kanji",  x = 5.30, y = 1.10, mask_x_bias = 0.05,  mask_y_bias = -.3, kanji_x_bias = 0, kanji_y_bias = 0.16, mask_w = 3.5, kanji_w = 2.60, r =  0.0,
        parts = {
            { id = "shin_kanji_stroke", key = "_jp2_shin_kanji_stroke", stage = "preparation", x_bias = 0.50, y_bias = 1.15, w = 2.9, r = 0.0, face_layer = 40 },
        },
        decorators = {
            --- chopsticks
            { id = "chop_down", atlas = "title_pack", key = "chop_down", stage = "title", x_bias = .80, y_bias = 1.70, w = 2.43, r = 0.0, tint = cw, dist = 2.1, shadow_layer = 35, face_layer = 40 },
            { id = "chop_up",   atlas = "title_pack", key = "chop_up",   stage = "title", x_bias = .70, y_bias = 1.30, w = 2.36, r = 0.0, tint = cw, dist = 2.1, shadow_layer = 10, face_layer = 30 },
        },
    },

    --- Kanji Meshi 
    { id = "meshi", mask = "_jp3_meshi_mask", kanji = "_jp3_meshi_kanji", x = 8.20, y = 0.85, mask_x_bias = 0.4,   mask_y_bias = -.2, kanji_x_bias = 0,   kanji_y_bias = 0.16, mask_w = 4.35, kanji_w = 3.20, r = 0.0,
        parts = {
            { id = "meshi_kanji_roof", key = "_jp3_meshi_kanji_roof", stage = "both",        x_bias = 0.6,  y_bias = 0.,  w = 1.45, r = 0.0, face_layer = 40 },
            { id = "meshi_kanji_dot",  key = "_jp3_meshi_kanji_dot",  stage = "preparation", x_bias = 1.39, y_bias = 2.23, w = 0.55, r = 0.0, face_layer = 40 },
        },
        decorators = {
            --- rice_ball
            { id = "rice_ball_mask",     atlas = "icon_pack", key = "rice_ball_mask",     stage = "title", x_bias = 1.215, y_bias = 2.11, w = 0.74, r = 0.,  tint = ccrm,  dist = 2.0, shadow_layer = 10, face_layer = 30, manual_enter = Y },
            { id = "rice_ball_sea_weed", atlas = "icon_pack", key = "rice_ball_sea_weed", stage = "title", x_bias = 1.4, y_bias = 2.48, w = 0.4,     r = 0, tint = cw,    dist = 2.1, shadow_layer = 10, face_layer = 30, manual_enter = Y },
            { id = "rice_ball_line",     atlas = "icon_pack", key = "rice_ball_line",     stage = "title", x_bias = 1.2, y_bias = 2.11, w = 0.81,    r = 0., tint = ctd,   dist = 2.2, shadow_layer = 10, face_layer = 30, manual_enter = Y },
        },
    },
}

M.english = {
    paper = {
        id = "title_eng_paper", atlas = "icon_pack", key = "henshin_paper",
        x = 3.9, y = 4.3, w = 8, r = -0.02,
        tint = cpaper, dist = 1.5, shadow_alpha = 0.24,
        paint = { shader = "grass_sway", speed = 0.5 },
    },
    letters = {
        --- Henshin
        "_eng0_H",  "_eng1_e",   "_eng2_n1",  "_eng3_s1", "_eng4_h2",  "_eng5_i",  "_eng6_n2",

        --- Meshi
        "_eng7_M",  "_eng8_e2",  "_eng9_s2", "_eng10_h3", "_eng11_i2",
    },
}

return M
