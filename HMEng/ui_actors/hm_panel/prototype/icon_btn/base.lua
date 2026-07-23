local Y, N = true, false

return {
    --- basic settings
    type = "icon_btn",                  renderer = "btn_container",

    --- hit settings
    button     = Y,                     can_hover    = Y,
    can_click  = Y,                     can_drag     = N,
    hit_shape  = "rect",                hit_padding  = { x = 0.02, y = 0.06 },

    --- container settings
    shadow       = N,                   text_overlay       = N,
    hover_tint   = 0.,                click_visual_time  = 0.1,
    widget_dist  = 1,
}
