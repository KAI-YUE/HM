local Y, N = true, false

local M = {}

M.clear = { 0, 0, 0, 0 }

------------------------------------------
--- temporary layout tuning
------------------------------------------
M.show = { icons = Y, bars = Y, profile_visible = { player = N, foe = N } }

-------------------------------------------
--- drawing layer 
-------------------------------------------
M.layer = {
    panel           = 10,       profile_back    = 20,
    profile_picture = 30,       profile_front   = 40,
    icon            = 50,       bar             = 60,
}

--------------------------------------------
--- hud pos
--------------------------------------------
M.hud = {
    x = -1, y = 1, scale = 1,
    player = { x = 0, y = 0, scale = 1 },
    foe    = { x = 0, y = 0, scale = 1 },
}

-----------------------------------------------
--- panel pos
-----------------------------------------------
M.panel = {
    player = { x = 0,               y_from_bottom = 4.0,  w = 6.5 },
    foe    = { x_from_right = 6.2,  y = 0.55,             w = 5.35, h = 2.35 },
}
M.panel_pass = { x = -0.05, y = -0.05, w_pad = 0.10 }                      -- wh_ratio = 1.88

--- adjacent panel 
M.panel_2       = { x_from_right = 0.02, y = 2.55,   w = 4.58 }
M.panel_2_pass  = { x = -0.1, y = -0.035,  w_pad = 0.15, wh_ratio = 4.85 } -- wh_ratio 

return M
