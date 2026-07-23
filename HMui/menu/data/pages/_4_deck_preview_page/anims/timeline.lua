local M = {}

--------------------------------------------------
--- Deck preview cut-in timeline
--------------------------------------------------
M.cut_in = {
    --- absolute timestamps from cut-in start
    page_wipe_start         = 0.00,        back_fade_start       = 0.00,
    child_fade_start        = 0.12,        flip_start            = 0.10,
    snapshot_fade_start     = 0.12,

    --- durations and per-card cadence
    page_wipe_duration      = 0.68,        back_fade_duration    = 0.68,
    child_fade_duration     = 0.34,        flip_stagger          = 0.008,
    flip_in_duration        = 0.10,        flip_out_duration     = 0.14,

    --- snapshot settings 
    snapshot_fade_duration  = 0.56,
    snapshot_alpha_start    = 1.00,        snapshot_alpha_end    = 0.10,
    finish_padding          = 0.02,
}

return M
