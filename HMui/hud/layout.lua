local Y, N = true, false

local M = {}

M.clear = { 0, 0, 0, 0 }

-------------------------------------------
--- drawing layer 
-------------------------------------------
M.layer = {
    panel           = 10,       profile_back    = 20,
    profile_picture = 30,       profile_front   = 40,
    icon            = 50,       bar             = 60,
}

--------------------------------------------
--- drawing panel 
--------------------------------------------
M.panel = {
    player = { x = 1.5, y_from_bottom = 4.0, w = 5.8 },
    foe    = { x_from_right = 6.2, y = 0.55, w = 5.35, h = 2.35 },
}
M.panel_pass = { x = -0.05, y = -0.05, w_pad = 0.10 } -- wh_ratio = 1.88
M.panel_seam = {
    x = 0, y = 0, w_pad = 0,
    dash = "dash_1", gap_px = 9, scale = 1.0,
    points = { { 0.055, 0.190 }, { 0.170, 0.075 }, { 0.825, 0.070 }, { 0.955, 0.180 }, { 0.970, 0.765 }, { 0.855, 0.915 }, { 0.120, 0.925 }, { 0.040, 0.760 } },
}

M.panel_2       = { x = -0.1, y = 2.9, w = 5.9 }
M.panel_2_pass  = { x = -0.1, y = -0.05, w_pad = 0.15, wh_ratio = 5.55 } -- wh_ratio = 5.98
M.panel_2_seam  = {
    x = 0, y = 0, w_pad = 0,
    dash = "dash_1", gap_px = 9, scale = 1.0,
    points = { { 0.035, 0.250 }, { 0.100, 0.090 }, { 0.900, 0.090 }, { 0.965, 0.250 }, { 0.925, 0.800 }, { 0.080, 0.800 } },
}

----------------------------------------------
--- profile
----------------------------------------------
M.profile = {
    player = { x = -0.34, y = -0.20, w = 2.12, h = 2.48 },
    foe    = { x = 3.72,  y = -0.20, w = 1.95, h = 2.32 },
}

M.profile_mask  = { 
    atlas_key = "icon_pack",    quad_key = "paper-1",
    x = -1,  y = 0,         w = 3,      h = 1, 
    relative = Y,           alpha_cutoff = 0.05,    -- mask texture alpha threshold; higher removes softer edge pixels
    draw = Y,               tint = { 1, 1, 1, 1 } 
}

M.profile_chara = { 
    x = 0,        y = 0,    h = 2, 
    relative = Y,           fit_axis = "height"
}

-------------------------------------------
--- icons
-------------------------------------------
M.icons = {
    profile = {
        player = { x = 0.18, y = 0.22, w = 0.82, h = 0.82 },
        foe    = { x = 4.08, y = 0.22, w = 0.82, h = 0.82 },
    },
    hp    = { x = 1.42, y = 0.32, w = 0.36, h = 0.36 },
    full  = { x = 1.42, y = 0.92, w = 0.36, h = 0.36 },
    money = { x = 1.42, y = 1.52, w = 0.36, h = 0.36 },
}

-------------------------------------------
--- bars 
-------------------------------------------
M.bar_bg = {
    hp   = { x = 1.88, y = 0.28, w = 2.65, h = 0.42 },
    full = { x = 1.88, y = 0.88, w = 2.65, h = 0.42 },
}

M.bars = {
    { key = "hp",   x = 1.95, y = 0.34, w = 2.50, h = 0.30 },
    { key = "full", x = 1.95, y = 0.94, w = 2.50, h = 0.30 },
}

------------------------------------------
--- strokes 
------------------------------------------
M.profile_strokes = {
    back  = {
        { quad_key = "profile_stroke_6", x = 0, y = 0, w = 1,  r = 0 },         -- top right corner 
        -- { quad_key = "profile_stroke_5", x = -1, y = 0.4, w = 0.8, r = 0 },  -- top left corner
       
    },
    --- lower quad draws at front 
    front = {
        { quad_key = "profile_stroke_4", x = -1, y = 0.3, w = 0.17, r = 0 }, -- left vertical line 
        { quad_key = "profile_stroke_2", x = -1., y = 0.9, w = 1, r = 0 },
        { quad_key = "profile_stroke_1", x = -0.75, y = 1.3, w = 0.8, r = 0 },
        { quad_key = "profile_stroke_3", x = 0., y = 1.2, w = 0.4, r = 0 },  -- bottom right corner
       
    },
}

return M
