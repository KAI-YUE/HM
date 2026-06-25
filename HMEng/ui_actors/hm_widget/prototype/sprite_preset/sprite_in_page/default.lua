local C = require("HMfns.animate.color.color_const")

local ccrm = C.CREAM
local Y, N = true, false

return {
    --- sprite settings
    renderer             = "single_sprite",
    atlas_key            = "icons",             fit_axis        = "width",
    sprite_mask_key      = N,

    --- hit settings
    type                 = "button",            button          = Y,
    can_drag             = N,                   hit_shape       = "rect",
    hit_padding          = { x = 0, y = 0 },

    --- color settings
    tint                 = ccrm,                sprite_color         = ccrm,
    fill_color           = N,                   shadow               = Y,
    shadow_color         = { 0, 0, 0, 0.30 },

    --- hover shader setting
    hover_face_shader    = N,                   hover_mask_shader    = N,
    hover_safe_time      = 0.1,                 hover_tint           = 0,
    hover_zoom           = 1,                   hover_shake          = N,
    click_visual_time    = 0,                   widget_dist          = 1,
}
