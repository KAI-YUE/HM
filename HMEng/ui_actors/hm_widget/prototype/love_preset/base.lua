local C = require("HMfns.animate.color.color_const")

local ck = C.BLACK
local ctl = C.UI.TEXT_LIGHT

local Y, N = true, false

return {
    -- hit setting
    button            = N,                    can_hover         = N,
    hit_shape         = "rect",
    hit_padding       = { x = 0, y = 0 },     hit_scale         = { x = 1, y = 1 },
    hit_offset        = { x = 0, y = 0 },

    -- shadow setting
    shadow            = Y,                    shadow_color      = { 0, 0, 0, 0.25 },

    -- color setting
    fill_color        = ck,                   idle_color        = { fill_color = ck, text_color = ctl },
    hover_tint        = 0.04,                 hover_color       = N,
    click_visual_time = 0.1,                  widget_dist       = 1,
    paint_alpha       = 1,

    -- text setting
    text_scale        = 0.52,                 text_color        = C.UI.TEXT_DARK,
    text_shadow       = Y,                    text_align        = { x = "center", y = "middle" },
    text_padding      = { x = 0, y = 0 },
    text_box_scale    = { x = 1, y = 1 },     text_offset   = { x = 0, y = 0 },
}
