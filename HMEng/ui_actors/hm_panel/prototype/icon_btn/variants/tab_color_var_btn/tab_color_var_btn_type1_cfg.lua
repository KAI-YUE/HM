local C, CUtils    = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")

local tint_alpha   = CUtils.tint_with_alpha
local lerp_colors  = CUtils.lerp_colors

local CP,    CUI    = C.PREVIEW, C.UI
local ctab          = CP.GRAY
local ctl,    ctd   = CUI.TEXT_LIGHT, CUI.TEXT_DARK
local cw,     ck    = C.WHITE,        C.BLACK
local csteel, ccrm  = C.STEEL,                 C.CREAM
local tsteel, tcrm  = tint_alpha(csteel, 0.5), tint_alpha(ccrm, 0.9)
local cmix = lerp_colors(csteel, ck, 0.4)
local tmix = tint_alpha(cmix, 0.8)
local tctl = tint_alpha(ctl, 0.6)

local Y, N = true, false

local M = {}

--------------------------------------------------
--- base & visuals
--------------------------------------------------
M.base = { id = "tab_color_var_btn", w = 1.82, h = 0.54 }

M.mask = {
    style     = "rbox",             atlas_key  = "ui_pack", 
    quad_key  = "tab_mask",         shadow     = Y,
}

M.label = {
    scale        = 0.28,             T      = { x = 0.58, y = 0.08, w_trim = 0.66, h = 0.36 },
    hover_color  = C.ORANGE,
}

--------------------------------------------------
--- state colors
--------------------------------------------------
M.color = {
    idle    = { mask = tmix,      label = tctl },
    active  = { mask = tcrm,      label = ctd },
}

return M
