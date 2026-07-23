local C, CUtils  = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")

local lerp_color = CUtils.lerp_colors

local czero, cs     = {0, 0, 0, 0}, {0, 0, 0, 0.28}
local CHUD,  cwo    = C.HUD,        {1, 1, 1, 0}

local ccrm  = C.CREAM
local cw,    ck     = C.WHITE,            C.BLACK
local cle,   chb    = CHUD.LIGHT_EDGE,    CHUD.BLUE_THEME
local chlg,  chdg   = CHUD.THEME_L_GREEN, CHUD.THEME_D_GREENS

local cs_shadow     = lerp_color(czero, chb, 0.5)
local c_lerp_edge   = lerp_color(ck, cle, 0.31)
local c_lerp_edge2  = lerp_color(czero, cle, 0.1)
local c_smudge1     = lerp_color(ccrm, chb, 0.8)
local c_smudge2     = lerp_color(ccrm, chb, 0.2)
local c_lerp_light  = lerp_color(chb, cle, 0.3)

local Y, N = true, false

local M = {}

----------------------------------------------
--- profile
----------------------------------------------
M.profile = {
    player = { x = -0.34, y = -0.20, w = 2.12, h = 2.48 },
    foe    = { x = 3.72,  y = -0.20, w = 1.95, h = 2.32 },
}

-------------------------------------------
--- drawing layer
-------------------------------------------
M.profile_layer = {
    mask     = 38,                 back            = 39,
    chara    = 40,                 front           = 41,
    contour  = 39,                 contour_detail  = 42,
    smudge   = 38.5,
}

--- profile_mask 
M.profile_mask  = { 
    --- basics 
    atlas_key = "hud_pack",        quad_key = "hud_masks",
    
    --- pos
    x         = 0.1,                y         = 0.10,
    w         = 1.32,               fit_axis  = "width",
    relative  = Y,                   
    
    --- color 
    alpha_cutoff  = 0.0,            -- mask texture alpha threshold; higher removes softer edge pixels
    edge_feather  = 1,              edge_px  = 2.25,
    draw          = Y,              tint     = cw,
    paint         = { shader = "profile_mask_gradient", color0 = c_lerp_light, color1 = chb, gradient_a = { 0., 0. }, gradient_b = { 1, 1 }, gradient_noise = 1/255 },

    --- canvas_related 
    source_px_h       = 1300,       canvas_pad = { x = 1.0, y = 2.0 },  --- controls the resolution of inner pic. 
    canvas_scale_max  = 5,
    
    extension = {
        { atlas_key = "hud_pack", quad_key = "hud_masks_extension_1", x = 0.8, y = 0.03, w = 0.65, fit_axis = "width", relative = Y, draw = N, tint = cw },
        { atlas_key = "hud_pack", quad_key = "hud_masks_extension_2", x = 0.3, y = 0.03, w = 0.51, fit_axis = "width", relative = Y, draw = N, tint = cw },
        { atlas_key = "hud_pack", quad_key = "hud_masks_extension_3", x = 0.68, y = 0.03, w = 0.25, fit_axis = "width", relative = Y, draw = N, tint = cw },
    },

    smudge_array = {
        draw        = Y,      atlas_key = "hud_pack",   relative    = Y,        quad_keys   = { "smudge_1", "smudge_2" },
        x           = 0.3,    y         = 0.10,         w           = 1,
        cols        = 6,      rows      = 6,            smudge_w    = 0.18,     alpha  = .7,
        col_gap     = 1.5,    row_gap   = 0.7,          row_bias_x  = 0.07,     quad_scale  = { smudge_1 = 1, smudge_2 = 0.75 },

        -- col_gap/row_gap: 1 keeps even spacing; >1 spreads; <1 tightens.
        -- row_bias_x: alternating horizontal row offset as a fraction of smudge array width.
        -- x: random horizontal offset per smudge, as a fraction of the smudge array width.
        -- y: random vertical offset per smudge, as a fraction of the smudge array height.
        -- r: random rotation range.
        -- scale: random size variation.
        jitter  = { x = 0.0, y = 0.035, r = 0.0, scale = 0.06 },

        -- {0, 0} -> {1, 1} top-left to bottom-right
        paint   = { color0 = c_smudge1, color1 = c_smudge2, gradient_a = { 0., 0. }, gradient_b = { 1, 1 }, gradient_noise = 1/255 },
        -- paint   = { color0 = ck, color1 = ck, gradient_a = { 0.1, 0.1 }, gradient_b = { 1, 1 }, gradient_noise = 1/255 },
    },

    contour = {
        { atlas_key = "hud_pack", quad_key = "profile_outer", x = 0.08, y = 0.10, w = 1.40, r = 0,      fit_axis = "width", relative = Y, tint = cle,          shadow = Y,  shadow_color = cs,        shadow_parallax = { x = 0.02, y = -0.01 },  widget_dist = 0.25 },
        { atlas_key = "hud_pack", quad_key = "1_lower",       x = 0.44, y = 1.25, w = 0.31, r = 0,      fit_axis = "width", relative = Y, tint = c_lerp_edge,  shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 0.08, y = -1 },     widget_dist = 0.25 },
        { atlas_key = "hud_pack", quad_key = "1_upper",       x = 0.36, y = 1.15, w = 0.63, r = 0,      fit_axis = "width", relative = Y, tint = c_lerp_edge2, shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 0.08, y = -1 },     widget_dist = 0.25 },
        { atlas_key = "hud_pack", quad_key = "2_lower",       x = 0.48, y = 1.28, w = 0.44, r = 0,      fit_axis = "width", relative = Y, tint = cle,          shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 0.08, y = -1 },     widget_dist = 0.25,  layer = 41.1 },
        { atlas_key = "hud_pack", quad_key = "2_inner",       x = 0.195, y = .79, w = 0.21, r = 0,      fit_axis = "width", relative = Y, tint = cle,          shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 0.08, y = -1 },     widget_dist = 0.25,  layer = 41. },
        { atlas_key = "hud_pack", quad_key = "4_5_inner",     x = 0.3, y = 0.24, w = 0.50,  r = -0.05,  fit_axis = "width", relative = Y, tint = cle,          shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 1.5, y = -1 },     widget_dist = 0.25,  layer = 39.1 },
        { atlas_key = "hud_pack", quad_key = "6_7_inner",     x = 0.93, y = 0.40, w = 0.46, r = 0.02,   fit_axis = "width", relative = Y, tint = cle,          shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 0.08, y = -1 },     widget_dist = 0.25, layer = 40.1 },
        { atlas_key = "hud_pack", quad_key = "6_inner",       x = 0.84, y = 0.18, w = 0.55, r = 0,      fit_axis = "width", relative = Y, tint = c_lerp_edge2, shadow = Y,  shadow_color = cs_shadow, shadow_parallax = { x = 0.08, y = -1 },     widget_dist = 0.25, layer = 39.1 },
    },
}

M.profile_chara = {
    x = 0.37,          y = 0.01,     h = 2,
    relative = Y,                    fit_axis = "height"
}

------------------------------------------
--- strokes 
------------------------------------------
M.profile_stroke_color_jitter = { enabled = Y, base = chb, target = chlg, amount = 0.35, seed = 19 }

M.profile_strokes = {
    back  = {
        shadow_parallax = { x = 0.08, y = -1 },
        { quad_key = "profile_stroke_8", x = .32,  y = 0.14, w = 0.75,  r = 0,     shadow_parallax = { x = 0.08, y = -1 } },
        { quad_key = "profile_stroke_6", x = 0.8, y = 0.14, w = 0.68,  r = 0,      shadow_parallax = { x = 0.08, y = 1 } },  --* top right corner
        { quad_key = "profile_stroke_5", x = 0.03, y = 0.21, w = 0.8,  r = -0.15,  shadow_parallax = { x = 0.08, y = -1 } },  --* top left corner
    },

    --- lower quad draws at front 
    front = {
        shadow_parallax = { x = -0.08, y = -1 },

        { quad_key = "profile_stroke_7", x = 1.32, y = 0.4,   w = 0.145,  r = 0,     shadow_parallax = { x = -0.08, y = -1 } },              --* right stroke 

        { quad_key = "profile_stroke_4", x = 0.19, y = 0.49,  w = 0.15,   r = -0.1,  shadow_parallax = { x = -0.08, y = -1 }, layer = 41.1 }, --* left vertical line
        { quad_key = "profile_stroke_2", x = 0.11, y = 0.735, w = 1,      r = -0.01, shadow_parallax = { x = -0.08, y = -1 } },              --* bottom left corner
        
        { quad_key = "profile_stroke_3", x = .91,  y = 1.02,  w = 0.45,   r = -0.02, shadow_parallax = { x = -0.08, y = -1 } },              --* bottom right corner
        { quad_key = "profile_stroke_1", x = .24,  y = 1.12,  w = 0.8,    r = 0,     shadow_parallax = { x = -0.08, y = -1 }, layer = 41.2 }, --* bottom middle
    },
}

return M
