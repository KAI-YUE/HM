return {
    white_birch = {
        model_def   = "resources/textures/map/terrain/_1_white_birch/_1_white_birch.model3.json",
        model       = {  fit_axis  = "height",  offset_x = 0,           offset_y = 0, 
            scale_x = 1,  scale_y  = 1,         ground_contact_x = 0.05 },

        vivid_color  = { 1.12, 1.08, 1.02, 1 },
        shadow_color = { 0, 0, 0, 0.28 },

        --------------------------------------------
        --- gust
        --- amp:        overall sway strength
        --- detail_amp: small leaf/branch flutter layered on top of amp
        --- gust_amp:   temporary burst strength used for stronger gust events
        --- offset:     baseline wind bias, usually kept near 0
        --------------------------------------------
        gust = {
            lo  = -1,     hi = 1,       --- Ranges of the params
            amp              = 1,       --- main trunk/canopy sway amount
            detail_amp       = 0.35,    --- fine motion for leaf jitter
            gust_amp         = 0.70,    --- extra peak amplitude during gusts
            primary_wait_min = 6,       --- minimum delay between primary gusts
            primary_wait_max = 10.2,    --- maximum delay between primary gusts
            offset           = 0,
            wind_speed       = 0.75,    --- speed of the base wind cycle
            detail_speed     = 2.1,     --- speed of the fine flutter cycle
            stiffness        = 16,      --- how quickly the model follows the target
            damping          = 3.0,     --- how quickly motion settles
            params = {
                --- Primary parameters move only with the independently timed structural gust.
                { id = "Param2",  scale = 0.72, primary = true, name = "tree_whole" },
                { id = "Param6",  scale = 1, offset = 0.03, primary = true, name = "crown" },
                { id = "Param10", scale = 1, name = "trunk" },
                { id = "Param3",  scale = 2, phase = 0.15, detail = 0.04, name = "leaf1" },
                { id = "Param4",  scale = 2, phase = 0.65, detail = 0.05, name = "leaf2" },
                { id = "Param5",  scale = 2, phase = 1.05, detail = 0.05, name = "leaf3" },
                { id = "Param7",  scale = 2, phase = 1.45, detail = 0.04, name = "leaf4" },
                { id = "Param8",  scale = 2, phase = 1.85, detail = 0.04, name = "leaf5" },
                { id = "Param9",  scale = 2, phase = 2.20, detail = 0.04, name = "leaf6" },
                { id = "Param",   scale = 1, phase = 2.65, detail = 0.03, name = "grass" },
            },
        },
    },
}
