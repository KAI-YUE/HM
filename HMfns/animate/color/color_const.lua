local color_utils = require("HMfns.animate.color.color_utils")
local _hex        = color_utils.hex_to_rgba

local C = {
    BLACK      = _hex("#3F3C3CFF"),         BLUE       = _hex("#86CADDFF"),     CREAM   = _hex("#F4F3F2FF"),
    CLEAR      = _hex("#00000000"),         GRAY       = _hex("#FAF2E2FF"),         
    GREEN      = _hex("#C5D296FF"),         DARK_GREEN = _hex("#618968FF"),     GRASS_GREEN = _hex("#68806CFF"),
    ORANGE     = _hex("#FCCA74FF"),         PURPLE     = _hex("#958A9BFF"),     RED     = _hex("#E8A9A3FF"),  
    SPGRAY     = _hex("#FAF2E2FF"),         STEEL      = _hex("#888889FF"),
    WHITE      = { 1, 1, 1, 1 },       
    
    HUD = {
       DARK = _hex("#423D3AFF"),            BLUE_THEME = _hex("#70A39EFF"),
    },

    UI = {
        YES         = _hex("#7AE81FFF"),    NO          = _hex("#E8A9A3FF"),
        TEXT_LIGHT  = _hex("#FDFFFEFF"),    TEXT_DARK   = _hex("#433F3EFF"), 
        ACTIVE      = _hex("#D9D7D3FF"),    INACTIVE    = _hex("#888889FF"),
        WIDGET_DARK = _hex("#2A2928FF")
    },

    DEC = {
        TAPE = _hex("#FFEDB8A3")
    },

    TITLE = {
        PAPER = _hex("#EEEBE2FF"),         UNDERLAY = _hex("#A49984FF"),
    },
    
    FX_MASK = {
        SOFT_LIGHT = { 1, 1, 1, 0.98 },           SOFT_DARK  = { 1, 1, 1, 0.6 },
        FX_DARK  = { 0.32, 0.32, 0.32, 0.98 },    FX_HOT = { 1.00, 0.92, 0.62, 1.0 },
        HOT_CANDIDATES = { { 1.00, 0.92, 0.62, 1.0 }, { 1.00, 0.86, 0.46, 1.0 }, { 0.98, 0.74, 0.28, 1.0 }, _hex("#D76F1FFF")}
    },
}


return C
