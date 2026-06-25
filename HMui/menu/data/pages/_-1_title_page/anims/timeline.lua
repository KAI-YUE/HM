local M = {}

----------------------------------------
--- Timeline for preparation stage
----------------------------------------
M.stage1 = {
    kanji_part_start   = 0.10,          kanji_part_step    = 0.08,
    kanji_part_fade    = 0.38,
}

----------------------------------------
--- Timeline for title stage
----------------------------------------
M.stage2 = {
    switch_fade        = 0.92,      focus_delay        = 0.98,
    control_lock_delay = 1.00,

    blur_fade          = 0.72,      blur_remove        = 0.78,

    old_part_fade      = 0.16,      old_press_fade     = 0.08,
}

----------------------------------------
--- Timeline for press decorators
----------------------------------------
M.press_decorators = {
    hat_drop       = 0.04,          rice_cut       = 0.08,
    chop_down      = 0.10,          chop_up        = 0.13,
}

----------------------------------------
--- Timeline for chopsticks idle cycle
----------------------------------------
M.chopsticks_cycle = {
    start_delay     = 0.92,          idle_duration = 3.40,
    active_duration = 0.82,          chops         = 2,
    down_angle      = 0.01,          up_angle      = -0.05,

    down_pivot_x    = 0.50,          down_pivot_y   = 0.50,
    up_pivot_x      = 0.50,          up_pivot_y     = 0.50,
}

----------------------------------------
--- Timeline for roof with pivot
----------------------------------------
M.roof_with_pivot = {
    pivot_rel_x = 0,                pivot_rel_y = -0.,

    idle_angle  = 0.18,             idle_drift  = 0.06,
    idle_lift   = 0.018,            idle_freq   = 0.6,
    idle_slow_angle = 0.035,
    idle_slow_freq  = 0.47,
}

return M
