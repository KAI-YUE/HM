local SharedSeeds = require("HMui.menu.data.pages._1_load_2_save_pages._shared.sampling_seed_lists")

return {
    back = SharedSeeds.back,

    ----------------------------------------
    --- tabs sampling_seeds for textfx (how the text looks like)
    ----------------------------------------
    tabs = {
        opt_audio   = { 
            32031 
        },
        opt_vision  = { 
            924931,
        },
        opt_control = { 
            5911,
        },
        opt_system  = { 
            24450,
        },
    },

    ---------------------------------------------------------
    --- paint sampling_seeds for how the rect looks like 
    ---------------------------------------------------------
    tab_paint_seed_entries = {
        opt_audio   = { seed = 2314503, x_mul = 0.05, y_mul = 0.7, w_mul = 2.55, h_mul = 6.8, wobble = 0.3, bleed = 0.5, feather_px = 0.1 },
        opt_vision  = { seed = 566562,  x_mul = 0.05, y_mul = 0.7, w_mul = 2.55, h_mul = 6.5, wobble = 0.2, bleed = 0.5, feather_px = 0.1 },
        opt_control = { seed = 550851,  x_mul = 0.05, y_mul = 0.7, w_mul = 2.8,  h_mul = 6.5, wobble = 0.2, bleed = 0.4, feather_px = 2 },
        opt_system  = { seed = 574719,  x_mul = 0.05, y_mul = 0.7, w_mul = 2.55, h_mul = 6.5, wobble = 0.3, bleed = 0.4, feather_px = 3 },
    },
}
