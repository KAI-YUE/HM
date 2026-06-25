local C      = require("HMfns.animate.color.color_const")
local CUtils = require("HMfns.animate.color.color_utils")

local tint_with_alpha = CUtils.tint_with_alpha

local CUI = C.UI

return {
    yes_idle      = tint_with_alpha(CUI.YES, 0.3),
    no_idle       = tint_with_alpha(CUI.NO, 0.3),
    yes_hover     = tint_with_alpha(CUI.YES, 0.7),
    no_hover      = tint_with_alpha(CUI.NO, 0.7),
    black         = C.BLACK,
    cream         = C.CREAM,
    text_light    = CUI.TEXT_LIGHT,
    white         = C.WHITE,
    backdrop_dim  = tint_with_alpha(C.STEEL, 0.4),
    shadow        = { 0, 0, 0, 0.26 },
}
