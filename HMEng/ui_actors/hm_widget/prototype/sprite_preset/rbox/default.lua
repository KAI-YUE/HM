local C = require("HMfns.animate.color.color_const")

local cw, ccrm, cgy = C.WHITE, C.CREAM, C.GRAY

local Y, N = true, false

return {
    --- sprite settings
    type                = "rbox",
    renderer            = "single_sprite",          atlas_key          = "ui_pack",
    fit_axis            = "width",
    quad_key            = "rbox1",                  sprite_mask_key    = "rbox1-mask",

    --- offsets (offsets in ratio)
    sprite_offset       = { x = 0, y = 0 },
    sprite_mask_offset  = { x = 0, y = 0.05 },      sprite_mask_scale  = 0.9,

    --- hit settings
    button              = N,                        hook_fn            = N,
    hit_shape           = "rect",                   hit_padding        = { x = 0., y = 0.0 },

    --- shadow & shader settings
    shadow = Y,                                     shadow_color  = { 0, 0, 0, 0.30 },
    hover_face_shader   = N,                        hover_mask_shader  = N,

    --- color settings
    tint          = cw,                             sprite_color  = ccrm,
    fill_color    = { 0.50, 0.58, 0.5, 0.82 },      can_hover     = Y,
    hover_color   = N,                              hover_tint        = 0.18,
    click_visual_time = 0.1,
    widget_dist   = 1,                              fill_inset    = 0,
    sprite_scale  = 1,
}
