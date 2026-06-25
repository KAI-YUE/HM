return {
    --- language selector 
    {
        key       = "language",                label_key  = "language",
        control   = "lr_selector",             widget     = "lang_selector",
        fallback  = "Language",
    },

    --- game_speed slider
    {
        key       = "g_speed",                 label_key  = "game_speed",
        control   = "slider",                  fallback   = "Game Speed",            

        --- params settings
        min_val   = 1,                         max_val    = 5,
        steps     = 4,                         default    = 2,
    },

    --- text_speed slider 
    {
        key             = "text_speed",        label_key              = "text_speed",
        control         = "slider",            fallback               = "Text Speed",
        description_key = "text_speed_demo",   finish_reveal_b4_fade  = true,
        i18n_scope      = "options.system",    description_font_type  = "SAB",       
        hover_dwell_by_text_speed = { [1] = 0.6, [2] = 0.5, [3] = 0.4, [4] = 0.3, [5] = 0.2, default = 0.4 },
        
        --- params settings 
        min_val  = 1,                          max_val  = 5,
        steps    = 4,                          default  = 3,
    },

    --- auto_save on_off_switcher
    {
        key      = "auto_save",                label_key  = "auto_save",
        control  = "on_off_switcher",          fallback   = "Auto Save",
        default  = true,
    },

    --- reset defaults widget_with_btn
    {
        key      = "reset_defaults",           label_key  = "reset_defaults",
        control  = "widget_with_btn",          fallback   = "Reset Defaults",
    },
}
