local C = require("HMfns.animate.color.color_const")

local ctl = C.UI.TEXT_LIGHT
local Y, N = true, false

return function(args)
    args = args or {}
    local id = args.id or "hid_hint"

    return {
        --- basics
        type       = "hid_hint",                 renderer    = "hid_hint",
        id         = id,                         hid_action  = args.hid_action or "delete",
        show_when  = args.show_when,

        --- hit settings
        button     = N,                          can_hover   = N,
        can_click  = N,                          can_drag    = N,
        can_collide = N,                         shadow      = N,

        --- child widgets
        child_widgets = {
            {
                style = "sprite_in_page",       id = id .. "_button",
                atlas_key = "ui_pack",          quad_key = args.quad_key or "btn_mask",
                T = { x = 0, y = 0, w = args.button_w or 0.52 },
                button = N,                      can_hover = N,
                can_click = N,                   can_drag = N,
                tint = ctl,                      sprite_color = ctl,
                shadow = Y,
            },
            {
                style = "text_widget",          id = id .. "_label",
                T = { x = 0.72, y = -0.02, w = args.label_w or 2.4, h = 0.52 },
                button = N,                      can_hover = N,
                can_click = N,                   can_drag = N,
                text = args.label or "Delete", text_color = ctl,
                text_scale = args.text_scale or 0.42,
                text_align = { x = "left", y = "middle" },
                text_shadow = Y,                 text_static = Y,
            },
        },
    }
end
