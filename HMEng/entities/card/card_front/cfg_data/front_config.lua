local C = require("HMfns.animate.color.color_const")

local _ccard = C.CARD

local M = {}

-----------------------------
--- frame presets
----------------------------
M.frames = {
    default = {
        frame_key   = "card_frame_1",   frame_scale = 0.8,
        frame_x     = 0,                frame_y     = 0,
    },

    alt = {
        frame_key   = "card_frame_2",   frame_scale = 1.0,
        frame_x     = 0,                frame_y     = 0,
    },
}

-----------------------------
--- base presets
----------------------------
M.base = {
    default = {
        base_color = _ccard.BASE,
    },
}

-----------------------------
--- main: card front preset
----------------------------
M.default = {
    base_color  = _ccard.BASE,
    frame_key   = "card_frame_1",
    frame_scale = 1.0,
    frame_x     = 0,
    frame_y     = 0,
}

return M
