local C       = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local CTTL = C.TITLE
local cpaper   = CTTL.PAPER
local ck, crm  = C.BLACK, C.CREAM
local co = C.ORANGE

local M = {}

M.colors = {
    text        = C.CREAM,                  line_shadow = tint_alpha(ck, 0.18),
    text_shadow = tint_alpha(ck, 0.22),     word_mask   = tint_alpha(CTTL.UNDERLAY, 0.69),
}

M.press = { x = 3.7, y = 6.85, w = 5.7, h = 0.85 }
M.prompt_center = { x = 10, y = 10 }

-----------------------------------------------------
--- shader related 
-----------------------------------------------------
M.paint = {
    prompt_glint  = { shader = "_1_sprite_glint_bloom", speed = 0.6, speed_factor = 1., wobble = 0.35, bleed = 0.08 },
    underlay_sway = { shader = "dr_sway", speed = 0.75 },
}

M.shader_fx = {
    prompt_squares = {
        shader = "title_prompt_squares", layer = "above_field", alpha = 0.96,
        T = { x = 7, y = 8, w = 6, h = 5 },
        uniforms = {
            speed        = 0.27, -- forward/depth travel speed
            projection   = 0.1,  -- straight-edge skew/perspective amount
            lift         = 0.55, -- upward drift strength
            density      = 0.5,  -- visible rect population
            brightness   = 3.,    -- final alpha/color intensity
            c1           = co, -- warm palette endpoint
            c2           = cpaper, -- soft cool palette endpoint
            square_scale = 1.0,  -- rect grid scale
            eye_open     = 0.58, -- vertical height of eye-shaped fade
            eye_soft     = 0.23, -- softness of eye-shaped fade edge
        },
    },
}

-------------------------------------------------------
--- word_mask
-------------------------------------------------------
M.word_mask_scale = 1.14
M.word_mask_paper = {
    id = "press_any_henshin_paper_mask",    atlas = "icon_pack",
    key = "henshin_paper",                  enabled = true,
    center_bias = 0, y_bias = -0.18, w = 5.3, h = 0.3, r = 0.0, dist = 0.53,
}

-------------------------------------------------------
--- underline 
-------------------------------------------------------
M.underline = {
    { id = "press_any_underline",       key = "_underline",       center_bias = 0,     y_bias = 0.235, w = 4.55, r = 0,   dist = 0.62 },
    { id = "press_any_underline_mark1", key = "_underline_mark1", center_bias = -0.01, y_bias = 0.265, w = 0.13, r = 0.0, dist = 0.64 },
    { id = "press_any_underline_mark2", key = "_underline_mark2", center_bias = -2.18, y_bias = 0.265, w = 0.15, r = 0.0, dist = 0.64 },
}

-------------------------------------------------------
--- letter 
-------------------------------------------------------
M.letters = {
    { key = "_pr_eng0_p",    step_w = 0.42, w = 0.32, y = 0.00 },
    { key = "_pr_eng1_r",    step_w = 0.31, w = 0.24, y = 0.12 },
    { key = "_pr_eng2_e",    step_w = 0.34, w = 0.28, y = 0.12 },
    { key = "_pr_eng3_s",    step_w = 0.28, w = 0.22, y = 0.12 },
    { key = "_pr_eng3_s_2",  step_w = 0.50, w = 0.22, y = 0.13 },

    { key = "_pr_eng4_A",    step_w = 0.43, w = 0.34, y = 0.07 },
    { key = "_pr_eng5_n",    step_w = 0.34, w = 0.27, y = 0.13 },
    { key = "_pr_eng6_y",    step_w = 0.55, w = 0.27, y = 0.12 },

    { key = "_pr_eng7_B",    step_w = 0.41, w = 0.32, y = 0.04 },
    { key = "_pr_eng8_u",    step_w = 0.34, w = 0.28, y = 0.14 },
    { key = "_pr_eng9_t",    step_w = 0.25, w = 0.18, y = 0.04 },
    { key = "_pr_eng10_t",   step_w = 0.25, w = 0.18, y = 0.04 },
    { key = "_pr_eng11_o",   step_w = 0.35, w = 0.29, y = 0.13 },
    { key = "_pr_eng12_n",   step_w = 0.31, w = 0.27, y = 0.13 },
}

M.word_masks = {
    { id = "press",  key = "_pr_press_cloud_mask",  first = 1, last = 5,  x_scale = 1.2, y_scale = 1.3, y_bias = 0.1 },
    { id = "any",    key = "_pr_any_cloud_mask",    first = 6, last = 8,  x_scale = 1.2, y_scale = 1.4, y_bias = 0.1 },
    { id = "button", key = "_pr_button_cloud_mask", first = 9, last = 14, x_scale = 1.1, y_scale = 1.6, y_bias = 0.1 },
}

return M
