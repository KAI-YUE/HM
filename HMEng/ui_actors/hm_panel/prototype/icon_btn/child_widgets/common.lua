local C, CUtils = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local CUI = C.UI
local cw, ck = C.WHITE, C.BLACK
local ctl, ctd = CUI.TEXT_LIGHT, CUI.TEXT_DARK

local N = false

local M = {
    cw = cw,
    ck = ck,
    ctl = ctl,
    ctd = ctd,
    tint_alpha = tint_alpha,
}

---____________________________
--- main: child_id
---______________________________________
function M.child_id(id, suffix) return id .. "_" .. suffix end

---____________________________
--- main: sprite_child
---______________________________________
function M.sprite_child(id, quad_key, T, args)
    return {
        --- basics
        style = "sprite_in_page",             T = T,
        id    = id,                           atlas_key = "icons",
        quad_key = quad_key,                  fit_axis = "width",

        --- hit settings
        button      = N,                      can_hover = N,
        can_click   = N,                      can_drag  = N,
        hover_zoom  = 1,

        --- color settings
        shadow       = args.shadow ~= N,      shadow_color       = args.shadow_color or tint_alpha(ck, 0.22),
        tint         = args.tint or ctl,      sprite_color       = args.sprite_color or args.tint or ctl,
        fill_color   = args.fill_color,       hover_color        = args.hover_color,
        hover_tint   = args.hover_tint or 0,
        widget_dist  = args.widget_dist or 1, parent_hover_tint  = args.parent_hover_tint,
    }
end

---____________________________
--- main: bg_T
---______________________________________
function M.bg_T(args)
    return {
        x = args.bg_x or 0,
        y = args.bg_y or 0,
        w = args.bg_w or 1.85,
        h = args.bg_h or args.h or (args.T and args.T.h) or 0.58,
        r = args.bg_r or 0,
    }
end

return M
