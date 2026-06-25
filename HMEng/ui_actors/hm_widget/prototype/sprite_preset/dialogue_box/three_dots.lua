local C       = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local cw, ccrm   = C.WHITE, C.CREAM
local tcw, tcrm  = tint_alpha(ccrm, 0.8), tint_alpha(ccrm, 0.7)

return {
    --- sprite setting
    quad_key           = "dialogue_box-1",          sprite_mask_key    = "dialogue_box-1-mask",
    sprite_mask_offset = { x = 0, y = 0.003 },      sprite_mask_scale  = 1.005,

    --- color settings
    tint               = cw,                        sprite_color       = { 1, 1, 1, 0.95 },
    fill_color         = tcrm,

    --- text settings
    text_scale         = 0.55,                      text_offset        = { x = 0.2,  y = 0.2 },
    text_padding       = { x = 0.55, y = 0.35 },

    -- decorator setting
    decorator_color    = tcw,                       decorator_cycle    = 2,
    decorator_hold     = 3.16,                      decorator_pause    = 0,
    decorator_pause_jitter = 0.50,
    decorators = {
        { quad_keys = { "dot-1", "dot-2" }, pos = { x = 0.905, y = 0.08 }, delay = 0.00, delay_jitter = 1,  },
        { quad_keys = { "dot-1", "dot-2" }, pos = { x = 0.925, y = 0.08 }, delay = 2, delay_jitter = 1,  },
        { quad_keys = { "dot-1", "dot-2" }, pos = { x = 0.945, y = 0.08 }, delay = 3, delay_jitter = 1,  },
    },
}
