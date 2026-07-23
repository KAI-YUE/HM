return {
    --- master volume slider
    {
        key       = "volume",                  label_key  = "master_volume",
        control   = "slider",                  fallback   = "Master Volume",

        --- params settings
        min_val   = 0,                         max_val    = 100,
        steps     = 100,                       default    = 50,
    },

    --- background music slider
    {
        key       = "music_volume",            label_key  = "background_music",
        control   = "slider",                  fallback   = "Background Music",

        --- params settings
        min_val   = 0,                         max_val    = 100,
        steps     = 100,                       default    = 50,
    },

    --- sound effects slider
    {
        key       = "SE_volume",               label_key  = "sound_effects",
        control   = "slider",                  fallback   = "Sound Effects",

        --- params settings
        min_val   = 0,                         max_val    = 100,
        steps     = 100,                       default    = 30,
    },

    --- voice volume slider
    {
        key       = "voice_volume",            label_key  = "voice_volume",
        control   = "slider",                  fallback   = "Voice Volume",

        --- params settings
        min_val   = 0,                         max_val    = 100,
        steps     = 100,                       default    = 50,
    },

    --- dialogue voice on_off_switcher
    {
        key       = "dialogue_voice",          label_key  = "dialogue_voice",
        control   = "on_off_switcher",         fallback   = "Dialogue Voice",
        default   = true,
    },
}
