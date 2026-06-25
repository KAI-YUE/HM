local C = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local cw, ccrm, cgy = C.WHITE, C.CREAM, C.GRAY
local csteel = C.STEEL
local tsteel = tint_alpha(csteel, 0.3)

local Y, N = true, false

return {
    --- sprite settings (offsets in ratio)
    type                = "button",                 hook_fn             = "toggle_debug",
    renderer            = "single_sprite",          atlas_key          = "ui_pack",
    fit_axis            = "square",
    quad_key            = "circle-1",               sprite_mask_key    = "circle-1-mask",

    sprite_offset       = { x = 0, y = 0 },
    sprite_mask_offset  = { x = 0, y = 0.05 },      sprite_mask_scale  = 0.9,

    --- hit settings
    button              = Y,
    hit_shape           = "ellipse",                hit_padding        = { x = 0., y = 0.0 },

    --- shadow & shader settings
    shadow = Y,                                     shadow_color  = { 0, 0, 0, 0.30 },
    hover_face_shader   = "_1_circular",               hover_mask_shader  = "toon_focus",

    --- color settings
    tint          = cw,                             sprite_color  = ccrm,
    fill_color    = tsteel,                         can_hover     = Y,
    hover_color   = N,                              hover_tint        = 0.18,
    click_visual_time = 0.1,
    widget_dist   = 1,                              fill_inset    = 0,
    sprite_scale  = 1,
}
