local C       = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local cw, ccrm = C.WHITE, C.CREAM
local crd, csteel = C.RED, C.STEEL

local tsteel = tint_alpha(csteel, 0.3)
local trd = tint_alpha(crd, 0.3)

local Y, N = true, false

return {
    --- sprite setting
    quad_key           = "circle-1",            sprite_mask_key    = "circle-1-mask",
    sprite_offset      = { x = 0, y = 0. },      sprite_mask_offset = { x = 0, y = 0.0 },
    sprite_mask_scale  = 0.93,

    --- hit setting
    hit_shape          = "ellipse",             hit_padding        = { x = 0, y = 0 },

    --- shadow setting
    shadow             = Y,                     shadow_color       = { 0, 0, 0, 0.1 },
    hover_face_shader  = "_1_circular",            hover_mask_shader  = N,

    --- color setting
    tint               = cw,                    sprite_color       = ccrm,
    fill_color         = tsteel,

    click_visual_time  = 0.2,

    hover_color = {
        fill_color = trd,       -- mask
        sprite_color = ccrm,    -- face sprite
        tint = ccrm,            -- face fallback         -- tint
    },

    --- misc
    widget_dist        = 1,                     sprite_scale       = 1,
    fill_inset         = 0,
}
