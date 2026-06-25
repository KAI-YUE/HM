local C        = require("HMfns.animate.color.color_const")
local CUtils   = require("HMfns.animate.color.color_utils")
local MiniPage = require("HMui.menu.data.pages.deck_preview_page.mini_page")

local tint_alpha = CUtils.tint_with_alpha

local Y, N = true, false

local M = {}

--------------------------------------------------
--- build deck preview page
--------------------------------------------------
function M.build(gm, selected, hooks)
    local RT = gm._room.T
    return {
        style = "stroked_page", widget_style = "stroked_page",
        id = "deck_view_page",
        T = { x = RT.x + 0.28, y = RT.y + 0.16, w = RT.w - 0.56, h = RT.h - 0.34 },
        quad_key = "h-stroke-3",
        fill_color = N, stroke_color = tint_alpha(C.CREAM, 0.82),
        shadow = Y, shadow_color = { 0, 0, 0, 0.24 },
        seam_shader = "_0_seam_feather", seam_feather = 5,
        page_colors = { tint_alpha(C.STEEL, 0.16), tint_alpha(C.CREAM, 0.10) },
        widget_dist = 2,
        split = {
            x = 0.5, y = 0.5, r = 0.015,
            region = { axis = "vertical", ox = 0, oy = 0, oy_base = "w", ["or"] = -0.005 },
            stroke = { stroke_key = "h-stroke-3", ox = 0, oy = 0, oy_base = "w", scale = 0.08 },
        },
        child_widgets = {},
        attached_panel = MiniPage.build(gm, selected, hooks),
    }
end

return M
