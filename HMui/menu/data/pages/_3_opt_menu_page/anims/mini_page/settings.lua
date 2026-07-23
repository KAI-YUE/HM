local M = {}

-----------------------------
--- enter/exit settings
-----------------------------
M.ENTER = { queue = "opt_menu_enter", start_delay = 0.2,             curtain_duration = 0.9, textfx_stagger = 0.2 }
M.EXIT  = { queue = "opt_menu_exit",  pull_to = { x = 2, y = -6.2 }, pull_duration = 0.62,  curtain_pull_y = -6.2 }

------------------------------------------------------
--- start offsets & enter positions
------------------------------------------------------
M.START = { root = 0.16, tab_header = 0.16, polygon = 0.47, cascade = 0.17, gear = 0.7, textfx = 0.55 }
M.FROM  = {
    root       = { x = 2,    y = -6.2 },
    tab_header = { x = 2,    y = -6.2 },
    cascade    = { x = 1.25, y = -5.35 },
    gear       = { x = 3.35, y = -3.6 },
}

M.DILATION = { mini = 2, gear = 2 }

-----------------------------
--- spring shapes
-----------------------------
M.SPRING = {
    mini = {
        { t = 0.34, x =  0.10,  y =  0.42, ease = "sine" },
        { t = 0.20, x = -0.05,  y = -0.19, ease = "sine" },
        { t = 0.16, x =  0.025, y =  0.08, ease = "sine" },
        { t = 0.12, x =  0,     y =  0,    ease = "sine" },
    },
    gear = {
        { t = 0.30, x =  0.08,  y =  0.55, ease = "sine" },
        { t = 0.18, x = -0.04,  y = -0.25, ease = "sine" },
        { t = 0.14, x =  0.02,  y =  0.10, ease = "sine" },
        { t = 0.12, x = -0.01,  y = -0.04, ease = "sine" },
        { t = 0.10, x =  0,     y =  0,    ease = "sine" },
    },
}

---------------------------------------
--- hint btn
---------------------------------------
M.HINT = { fade_time = 1 }

return M
