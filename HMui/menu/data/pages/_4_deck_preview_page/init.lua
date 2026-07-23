local C, CUtils     =  require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local Body          = require("HMui.menu.data.pages._4_deck_preview_page.preview_body")
local Layout        = require("HMui.menu.data.pages._4_deck_preview_page.preview_layout")
local Tabs          = require("HMui.menu.data.pages._4_deck_preview_page.preview_tabs")

local tint_alpha    = CUtils.tint_with_alpha


local CP,     CUI   = C.PREVIEW, C.UI
local ctab          = CP.GRAY
local ck,     cw    = C.BLACK,                 C.WHITE
local csteel, ccrm  = C.STEEL,                 C.CREAM
local tsteel, tcrm  = tint_alpha(csteel, 0.5), tint_alpha(ccrm, 0.9)
local l_page        = tint_alpha(ck, 0.2)

local Y, N = true, false

local M = {}

--------------------------------------------------
--- page children
--------------------------------------------------
--- Helper: tab controls
local function tab_controls(gm, page_w, selected, hooks)
    local T = Layout.tabs.T
    return {
        style  = "empty_container",                         T                = { x = 0.5*(page_w - T.w) + T.x, y = T.y, w = T.w, h = T.h },
        id     = "deck_view_tab_controls",                  page_draw_layer  = "under_stroke",
        
        child_widgets = Tabs.build(gm, selected, hooks),
    }
end

--- Helper: page children
local function page_children(gm, selected, hooks, suits, page_w)
    local children = Body.build(gm, suits)
    children[#children + 1] = tab_controls(gm, page_w, selected, hooks)
    return children
end

--------------------------------------------------
--- build deck preview page
--------------------------------------------------
function M.build(gm, selected, hooks, suits)
    local RT      = gm._room.T
    local page_w  = RT.w - 0.56
    return {
        --- basics 
        style = "stroked_page",                  widget_style      = "stroked_page",
        id    = "deck_view_page",                scroll_target_id  = Body.list_id,

        T     = { x = RT.x + 0.28, y = RT.y + 0.16, w = page_w, h = RT.h - 0.34 },
        
        --- color_setting 
        fill_color   = N,                        stroke_color  = tcrm,
        shadow       = Y,                        shadow_color  = { 0, 0, 0, 0.24 },
        widget_dist  = 0.5, 

        --- cut-in shader
        fx_mask_shader = "_-1_page_wipe",        fx_mask_ref = "room",

        -- seam_shader  = "_0_seam_feather",        seam_feather  = 5,
        seam_shader   = nil, 
        page_colors   = { l_page, l_page },

        split = {
            x = 0.1,        y = 0.5,            r = 0.015,
            region = { axis        = "vertical",      ox = 0,    oy = 0.2, oy_base = "w", ["or"] = -0.005 },
            stroke = { stroke_key  = "long_stroke_1", ox = -0.1, oy = 0,   oy_base = "w", scale = 0.13, paint = Layout.stroke.paint },
        },

        child_widgets = page_children(gm, selected, hooks, suits, page_w),
    }
end

return M
