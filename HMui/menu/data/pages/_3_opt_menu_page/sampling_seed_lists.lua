local SharedSeeds = require("HMui.menu.data.pages._1_load_2_save_pages._shared.sampling_seed_lists")

return {
    back = SharedSeeds.back,

    tabs = {
        opt_audio   = { 
            32031 
        },
        opt_vision  = { 
            924931,
        },
        opt_control = { 
            17550,
        },
        opt_system  = { 
            24450,
        },
    },
}
