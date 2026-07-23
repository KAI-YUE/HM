return {
    --- graphics quality selector
    {
        key       = "graphics_quality",        label_key  = "graphics_quality",
        control   = "lr_selector",             widget     = "graphics_quality_selector",
        fallback  = "Graphics Quality",
        default   = "medium",
    },

    --- screen mode selector
    {
        key       = "screenmode",              label_key  = "screen_mode",
        control   = "lr_selector",             widget     = "screenmode_selector",
        fallback  = "Screen Mode",
    },

        --- resolution selector
    {
        key       = "resolution",              label_key  = "resolution",
        control   = "lr_selector",             widget     = "resolution_selector",
        fallback  = "Resolution",
    },

    --- frame rate limit selector
    {
        key       = "fps_cap",                 label_key  = "frame_rate_limit",
        control   = "lr_selector",             widget     = "fps_cap_selector",
        fallback  = "Frame Rate Limit",
        default   = 500,
    },

    --- v_sync on_off_switcher
    {
        key       = "vsync",                   label_key  = "v_sync",
        control   = "on_off_switcher",         widget     = "v_sync_switcher",
        fallback  = "V Sync",
        default   = true,
    },
}
