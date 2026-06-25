local C      = require("HMfns.animate.color.color_const")
local CUtils = require("HMfns.animate.color.color_utils")
local Tabs   = require("HMui.menu.data.pages.deck_preview_page.tabs")

local tint_alpha = CUtils.tint_with_alpha

local Y, N = true, false

local M = {}

--------------------------------------------------
--- build deck preview tab page
--------------------------------------------------
function M.build(gm, selected, hooks)
    local RT = gm._room.T
    return {
        style = "stroked_page", widget_style = "stroked_page",
        id = "deck_view_tab_page",
        T = { x = RT.x + 0.5*(RT.w - 7.2), y = RT.y + 0.18, w = 7.2, h = 0.82 },
        quad_key = "h-stroke-3",
        fill_color = N, stroke_color = tint_alpha(C.CREAM, 0.95),
        shadow = Y, shadow_color = { 0, 0, 0, 0.25 },
        seam_shader = N, seam_feather = 5,
        page_colors = { C.CLEAR, C.CLEAR },
        widget_dist = 2,
        split = {
            x = 0.5, y = 0.5, r = -0.02,
            region = { axis = "vertical", ox = 0, oy = 0, oy_base = "w" },
            stroke = { stroke_key = "h-stroke-3", ox = 0, oy = 0, oy_base = "w", scale = 0.08 },
        },
        card_textfx = Tabs.build(selected, hooks),
        child_widgets = {},
    }
end

return M
