local C, CUtils = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local Y, N = true, false

local M = {}

----------------------------------------------
--- Helper: sprite_widget
----------------------------------------------
function M.sprite_widget(id, atlas_key, quad_key, T, args)
    args = args or {}
    return {
        --- basics
        style = "sprite_in_page",                T = T,  
        id = id,
        atlas_key = atlas_key,                   quad_key = quad_key,
        fit_axis = args.fit_axis or "width",
        room_ref = Y,                            shadow_layer = args.shadow_layer,
        face_layer = args.face_layer,

        --- hit settings
        button = N,                              can_click = N,
        can_hover = N,
        hover_zoom = 1,                          widget_dist = args.widget_dist or 1.8,

        --- color settings
        shadow = args.shadow ~= N,               shadow_color = args.shadow_color or tint_alpha(C.BLACK, 0.26),
        tint   = args.tint or C.CREAM,           sprite_color = args.sprite_color or args.tint or C.CREAM,

        --- paint
        paint = args.paint,

        --- switch animation
        page_switch_manual_enter = args.page_switch_manual_enter,
    }
end

function M.tint_alpha(color, alpha) return tint_alpha(color, alpha) end

return M
