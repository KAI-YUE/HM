local C      = require("HMfns.animate.color.color_const")
local CUtils = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local ccrm, csteel = C.CREAM, C.STEEL
local tcrm, tsteel = tint_alpha(ccrm, 0.7), tint_alpha(csteel, 0.7)

local Y, N = true, false

return {
    -- fundamental setting: not a btn
    button       = N,                          can_hover    = N,

    -- color setting
    stroke_color = ccrm,                       fill_color   = tsteel,

    strokes = {
        { quad_key = "h-stroke-3", x = 0.02, y = 0.00, w = 0.96, h = 0.18 },
        { quad_key = "h-stroke-1", x = 0.02, y = 0.80, w = 0.96, h = 0.20 },
        { quad_key = "stroke-0",   x = 0.00, y = 0.08, w = 0.12, h = 0.84 },
        { quad_key = "stroke-1",   x = 0.88, y = 0.08, w = 0.12, h = 0.84 },
    },
}
