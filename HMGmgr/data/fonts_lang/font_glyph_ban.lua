return {
    global = {
        -- Gsans_textfx        = { "C" },
        ZCOOLXW_textfx      = { "i" },
        HachiMaruPop_textfx = { "a", "D", "g", "i", "j", "l" },
        ZCOOL_textfx        = { "a", "C", "c", "D", "i", "T", "O", "o", "S",  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },

        ransom1_textfx      = { "a", "C", "c", "D", "d", "e", "i", "l", "o", "S" },
        ransom2_textfx      = { "C", "c", "i", "O", "o", "u", "r", "S", "t" },
        ransom3_textfx      = { "O", "o", "I", "i",  },
        ransom4_textfx      = { "A", "a",  "c", "D", "g", "L", "o", "O", "T", "8" },
        ransom5_textfx      = { "C", "D", "d",  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },
    },

    -- language specific ban table 
    langs = {
        zh_CN = {
            ZCOOLXW = {
                ["回"] = { fallback = "SAB", y_offset = -0.05 },
            },
        },
    },
}
