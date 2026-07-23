local M = {}

-------------------------------------------------
--- Hybrid timeline
-------------------------------------------------
M.hybrid = {
    overlap_delay = 0.25,
}

-------------------------------------------------
--- Page tunnel timeline
-------------------------------------------------
M.tunnel = {
    --- duration settings
    duration         = 1.0,         time_dilation = 3.5,
    reveal_time      = 0.22,        phases        = { 0.95, 0., 0.05 },  
    
    --- cover wipe settings
    cover_wipe_start = 0.0,         cover_wipe_end   = 1.0,
}

-------------------------------------------------
--- Page animator timeline
-------------------------------------------------
M.animator = {
    --- duration settings 
    duration            = 1.5,      time_dilation       = 1.0,
    wipe_duration       = 0.58,

    --- progress threshold that marks the transition as fully covered
    cover_point         = 1.0,

    --- zoom timeline
    zoom_delay          = 0.5,      zoom_duration       = 2.7,

    --- offset timeline
    offset_delay        = 0.,       offset_duration     = 3,

    alpha_fade_duration = 0.25,
}

return M
