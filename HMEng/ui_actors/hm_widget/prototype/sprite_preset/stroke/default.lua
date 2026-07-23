local C      = require("HMfns.animate.color.color_const")
local CUtils = require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local cw, ccrm = C.WHITE, C.CREAM
local tfill    = tint_alpha(C.STEEL, 0.22)

local Y, N = true, false

return {
    -- sprite setting
    type               = "stroke",
    button             = N,                         hook_fn           = N,
    renderer           = "stroke",                  atlas_key         = "ui_pack",
    fit_axis           = "width",

    -- hit setting
    hit_shape          = "rect",                    hit_padding       = { x = 0, y = 0 },

    -- color setting
    tint               = cw,                        stroke_color      = ccrm,
    fill_color         = tfill,                     can_hover        = N,                         can_collide      = N,
    hover_color        = N,                         hover_tint        = 0.12,
    click_visual_time  = 0,                         widget_dist       = 1,

    -- text setting
    text_scale         = 0.55,                      text_color        = C.UI.TEXT_DARK,
    text_wrap          = Y,                         text_line_spacing = 1.1,
    text_shadow        = Y,                         text_align        = { x = "left", y = "top" },
    text_offset        = { x = 0.2, y = 0.2 },      text_padding      = { x = 0.55, y = 0.35 },

    -- stroke
    strokes = {
        { quad_key = "h-stroke-1", },
        { quad_key = "h-stroke-2", },
        { quad_key = "h-stroke-3", },
    },
}
