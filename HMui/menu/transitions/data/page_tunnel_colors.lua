local C = require("HMfns.animate.color.color_const")

local M = {}

-------------------------------------------------
--- Helper: tones
-------------------------------------------------
local function tones(light, mid, accent)
    return {
        tunnel_tone_light  = light,
        tunnel_tone_mid    = mid,
        tunnel_tone_accent = accent,
    }
end

M.default = tones(C.GREEN, C.DARK_GREEN, C.SPGRAY)

M.title_new_game = tones(
    C.GREEN,
    C.DARK_GREEN,
    C.SPGRAY
)

M.pause_return_title = tones(
    C.GREEN,
    C.CREAM,
    C.STEEL
    -- C.CREAM
)

return M
