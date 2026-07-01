local Y = true

local M = {}

----------------------------------------------
--- profile
----------------------------------------------
M.profile = {
    player = { x = -0.34, y = -0.20, w = 2.12, h = 2.48 },
    foe    = { x = 3.72,  y = -0.20, w = 1.95, h = 2.32 },
}

--- profile_mask 
M.profile_mask  = { 
    --- basics 
    atlas_key = "hud_pack",        quad_key = "hud_masks",
    
    --- pos
    x         = 4,                 y         = 0,  
    w         = 1.3,               fit_axis  = "width",
    relative  = Y,                   
    
    --- color 
    alpha_cutoff  = 0.0,           -- mask texture alpha threshold; higher removes softer edge pixels
    edge_feather  = 1,             edge_px  = 2.25,
    draw          = Y,             tint     = { 1, 1, 1, 1 },

    --- canvas_related 
    source_px_h       = 1300,      canvas_pad = { x = 1.0, y = 2.0 },  --- controls the resolution of inner pic. 
    canvas_scale_max  = 5,
    
    extension = {
        { atlas_key = "hud_pack", quad_key = "hud_masks_extension_1", x = -1.00, y = 0.00, w = 0.65, fit_axis = "width", relative = Y, draw = Y, tint = { 0.45, 0.8, 1, 0.55 } },
        { atlas_key = "hud_pack", quad_key = "hud_masks_extension_2", x = -0.50, y = 0.00, w = 0.51, fit_axis = "width", relative = Y, draw = Y, tint = { 0.45, 0.8, 1, 0.55 } },
        { atlas_key = "hud_pack", quad_key = "hud_masks_extension_3", x = -0.25, y = 0.00, w = 0.25, fit_axis = "width", relative = Y, draw = Y, tint = { 0.45, 0.8, 1, 0.55 } },
    },
    contour   = { atlas_key = "hud_pack", quad_key = "profile_outer",          x = 0.08,  y = 0.1, w = 1.4, fit_axis = "width", relative = Y, tint = { 1, 1, 1, 1 } },
}

M.profile_chara = { 
    x = 0,        y = -0.05,     h = 2, 
    relative = Y,             fit_axis = "height"
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
