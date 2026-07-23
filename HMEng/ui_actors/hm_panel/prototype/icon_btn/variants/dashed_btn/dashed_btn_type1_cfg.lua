local C, CUtils = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")

local tint_alpha = CUtils.tint_with_alpha

local ccrm, co = C.CREAM, C.ORANGE
local ctd = C.UI.TEXT_DARK
local cddim = tint_alpha(ctd, 0.38)
local cshadow = tint_alpha(C.BLACK, 0.30)

local M = {}

M.base = {
    w = 2,                            h = 0.15,
}

M.hit = {
    scale   = { x = 2.4, y = 7 },     offset  = { x = 1.5, y = 0.6 },
}

M.icon = {
    quad_key  = "log",                w  = 0.46, 
    x         = 0.20,                 y  = 0.13,
    
    tint = ccrm,                      hover_color = co,
}

M.label = {
    x = 1.24,                         y            = 0.12,
    w = 0.92,                         h            = 0.38,
    text_scale      = 0.60,           color        = ctd,   
    disabled_color  = cddim,          hover_color  = co,
}

M.bg = {
    style   = "paint_rect",           color         = ctd,
    shadow  = true,                   shadow_color  = cshadow,
}

M.paint = {
    shader  = "_1_watercolor_edge",   wobble = 1,
    bleed   = 1,                      feather_px = 1,
}

M.widget_dist = 0.5

return M
