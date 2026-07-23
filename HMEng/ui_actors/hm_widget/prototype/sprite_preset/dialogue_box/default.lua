local C       = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local cw, ccrm = C.WHITE, C.CREAM
local ctd, ctl = C.UI.TEXT_DARK, C.UI.TEXT_LIGHT

-- preprocessed colors
local tcrm = tint_alpha(ccrm, 0.7)

local Y, N = true, false

return {
    --- sprite settings (offsets in ratio)
    type                = "dialogue_box",
    renderer            = "dialogue_box",           atlas_key          = "ui_pack",
    fit_axis            = "width",
    quad_key            = "dialogue_box-1",

    --- sprite mask setting
    sprite_mask_key    = "dialogue_box-1-mask",
    sprite_offset       = { x = 0, y = 0 },
    sprite_mask_offset  = { x = 0, y = 0.003 },     sprite_mask_scale  = 1.005,

    --- hit settings
    hit_shape           = "rect",                   hit_padding        = { x = 0, y = 0 },
    button              = N,                        hook_fn            = N,

    --- shadow & shader settings
    shadow              = N,                        shadow_color       = tcrm,
    hover_face_shader   = N,                        hover_mask_shader  = N,

    --- color settings
    tint                = cw,                       sprite_color       = cw,
    fill_color          = tcrm,                     can_hover        = N,                         can_collide      = N,
    hover_tint          = 0,                        click_visual_time  = 0,
    widget_dist         = 0,

    --- text settings
    text_scale          = 0.55,                     text_color         = ctd,
    text_wrap           = Y,                        text_line_spacing  = 1.1,
    text_reveal         = Y,                        text_reveal_rate   = 45,
    text_shadow         = Y,                        text_align         = { x = "left", y = "top" },
    text_offset         = { x = 0.2, y = 0.2 },     text_padding       = { x = 0.55, y = 0.35 },
}
