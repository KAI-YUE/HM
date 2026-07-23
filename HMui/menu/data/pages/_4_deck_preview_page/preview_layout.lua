local CardDimensions = require("HMGmgr.data.global.card_dimensions")

local _safe_margin   = 0.1

local M = {}

--------------------------------------------------
--- deck preview zone layout
--------------------------------------------------
M.zone = {
    --- basics
    T  = { x = 0.94, y = 0, w_trim = 1.02 },        shadow_heights  = { idle = 0.04, hover = 0.06, active = 0.06, dealing = 0.10 },

    --- jitter setting
    pad_x          = 0.08,                          pad_y      = 0.08,
    overlap_x      = 0.18,                          max_scale  = 0.8,
    jitter_x       = 0.015,                         jitter_y   = 0.015,
    jitter_r       = 0.006,     
    
    --- lift setting 
    hover_lift     = 0.05,                          highlight_lift = 0.05,
}

--------------------------------------------------
--- deck preview body layout
--------------------------------------------------
local zcfg = M.zone
M.body = {
    T = { x = -0.2, y = 1.22, w_trim = 2.4 },   --- -- Body width: width = room.T.w - Data.body.T.w_trim

    --- row config & scrollable page setting
    row_gap            = 0.01,                      row_h = CardDimensions.h*zcfg.max_scale + 2*_safe_margin,
    visible_count      = 4,
    scroll_step_ratio  = 0.55,                      scroll_speed = 18,

    --- slide bar
    slide_bar = { x_pad = 0.12, y_pad = 0.20, w = 0.52, r = -0.4 },

    --- suit tag
    suit_tag = {
        T           = { x = 0.02, y = 0.20, w = 1.28, h = 0.84 },
        label_T     = { x = 0.12, y = 0.12, w = 1.04, h = 0.56 },
        text_scale  = 0.22,                          font_variant = "small_ui",
    },
}

--------------------------------------------------
--- deck preview page data
--------------------------------------------------
M.default_key = "remaining"
M.tabs    = { T = { x = -6, y = -0.25, w = 7.2, h = 0.82 } }
-- M.stroke  = { paint = { shader = "paper_sway", speed = 0.35, shader_id = 4 } }
M.stroke  = { paint = { shader = nil, speed = 0.05, shader_id = 4 } }

--------------------------------------------------
--- cut-in animation
--------------------------------------------------
M.cut_in = {
    page_wipe_time    = 0.68,                       deal_start_delay = 0.36,
    child_fade_delay  = 0.12,                       child_fade_time  = 0.34,
    deal_delay        = 0.04,
    wave_gap          = 0.055,                      card_stagger     = 0.012,
    flip_delay        = 0.13,                       flip_in_time     = 0.10,
    flip_out_time     = 0.14,                       settle_time      = 0.58,

    --- waypoint setting
    waypoint_lift     = 0.52,                        waypoint_ratio   = 0.56,
    waypoint_arrive   = 0.18,                        waypoint_smooth  = 0.12,
    waypoint_speed    = 58,                          landing_smooth   = 0.15,
    landing_speed     = 42,
}

M.ordered = { --- ordered tab's layout
    {
        key          = "remaining",                  mask  = "tab_mask",
        float_phase  = 0.35,                         T     = { x = 0.0, y = -0.33, w = 3.5, h = 0.54, r = 0.1 },

        label = { 
            --- i18n setting 
            fallback      = "Remaining",             i18n_type  = "ui", 
            i18n_scope    = "deck_preview.tabs",     i18n_key   = "remaining", 

            --- font setting
            font_variant  = "small_ui",              align      = { x = "center", y = "middle" }, 
            offset        = { x = 0, y = 0.2 },      scale      = 0.45 
        },
    },
    {
        key          = "full_deck",                  mask  = "tab_mask_2",
        float_phase  = 2.1,                          T     = { x = 4.08, y = -0.26, w = 3.5, h = 0.54, r = 0.02 },

        label = {
            --- i18n setting
            fallback      = "Full Deck",             i18n_type  = "ui",
            i18n_scope    = "deck_preview.tabs",     i18n_key   = "full_deck",

            --- font setting
            font_variant  = "small_ui",              align      = { x = "center", y = "middle" },
            offset        = { x = 0, y = 0.13 },     scale      = 0.45
        },
    },
}

--------------------------------------------------
--- active tab floating motion
--------------------------------------------------
M.floating_log = {
    --- master controls
    --- drama scales every x/y/r displacement; 0 disables motion, 1 is neutral, >1 exaggerates it.
    --- tempo scales model time; <1 feels heavy/calm, >1 feels light/energetic.
    drama        = 2,         tempo        = 1.,

    --- idle buoyancy
    --- lift is the constant rise; heave is vertical bob; roll is angular bob in radians.
    --- drift is horizontal travel; freq is wave speed; harmonic adds irregular secondary-wave motion.
    lift         = 0.025,     heave        = 0.012,     roll         = 0.012,
    drift        = 0.01,      freq         = 1.6,       harmonic     = 0.22,

    --- selection settle
    --- settle_amp and settle_roll control the initial selection kick.
    --- settle_freq controls kick speed; higher settle_damp removes the kick sooner.
    settle_amp   = 0.035,     settle_roll  = 0.025,     settle_freq  = 8,
    settle_damp  = 4.5,

    --- runtime
    --- return_time is deselection recovery; step is the animation update interval.
    return_time  = 0.24,      step         = 1/60,
}

--------------------------------------------------
--- deck preview page lookup
--------------------------------------------------
M.by_key = {}
for _, tab in ipairs(M.ordered) do M.by_key[tab.key] = tab end

return M
