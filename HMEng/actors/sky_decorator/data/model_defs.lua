return {
    bird1 = {
        model_def   = "resources/textures/map/sky/bird1/bird1.model3.json",
        model       = { offset_x = 0, offset_y = 0, scale_x = 0.4, scale_y = 0.4 },
        draw_alpha  = 1,

        flyover = {
            duration = 4.8,      arc_y     = 0,                tilt = 0.04,
            wave_y   = 0.10,     wave_freq = 2.2,              ease = "smooth",
        },

        spawn = {
            --- basics
            enabled  = true,      max_active       = 1,          wait_min    = 8.0,
            wait_max = 18.0,      spawn_immediate  = true,       size_w      = 1.25,
            size_h   = 0.70,      draw_alpha       = 0.92,       x_span      = 0.62,
            x_min    = 0.12,      x_max            = 0.88,       bottom_pad  = 0.25,
            top_pad  = 0.85,
            
            --- speed setting
            vertical_speed_min_cells    = 0.08,     vertical_speed_max_cells    = 0.55,
            horizontal_speed_min_cells  = 0.08,     horizontal_speed_max_cells  = 0.55,

            --- scale setting
            end_scale_min    = 0.86,                end_scale_max     = 1.08,
            arc_y            = 0,                   wave_y_min_cells  = 0.04,
            wave_y_max_cells = 0.14,                wave_freq_min     = 1.4,
            wave_freq_max    = 2.6,                 tilt              = 0.04,
            ease             = "smooth",            flip_x            = 1,
        },

        param_drivers = {
            { id = "Param", kind = "cycle", curve = "sin01", cycle = 1, lo = -1, hi = 1, name = "fly" },
        },
    },
}
