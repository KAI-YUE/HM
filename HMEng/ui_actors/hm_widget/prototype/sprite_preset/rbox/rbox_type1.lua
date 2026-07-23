local C       = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local cw, ccrm   = C.WHITE, C.CREAM
local csteel     = C.STEEL
local tcw, tcrm  = tint_alpha(ccrm, 0.8), tint_alpha(ccrm, 0.7)

local tsteel = tint_alpha(csteel, 0.3)

local Y, N = true, false

return {
    -- fundamental setting, not a button
    button             = N,                    can_hover          = N,

    -- sprite setting
    quad_key           = "rbox1",              sprite_mask_key    = "rbox1-mask",
    sprite_mask_offset = { x = 0, y = 0.003 }, sprite_mask_scale  = 0.96,

    -- color setting
    tint               = N,                    sprite_color       = { 1, 1, 1, 0.95 },
    fill_color         = tsteel,
    click_visual_time  = 0,                    widget_dist        = 1,

    -- text setting
    -- text_scale         = 0.55,                  text_offset        = { x = 0.2,  y = 0.2 },
    -- text_padding       = { x = 0.55, y = 0.35 },
}
