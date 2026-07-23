local C, CUtils  = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local HintText   = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.hint_btn_cfg.hint_text_cfg")

local CTTL,   CUI   = C.TITLE,    C.UI
local ck,     co    = C.BLACK,    C.ORANGE
local cw,     ccrm  = C.WHITE,    C.CREAM
local cpaper, ctl   = CTTL.PAPER, CUI.TEXT_LIGHT

--- settings for sprite
local _fit_axis      = "none"
local _h_scale       = 0.85
local _bottom_raise  = 0.37
local _top_sink      = 0.1

local Y, N  = true, false

local M = {}

-----------------------------------------------------------
--- base & layout
----------------------------------------------------------
M.base = { 
    type          = "type3",                 label_suffix  = "_label",
    shadow_layer  = 1,                       face_layer    = 2,
}

M.layout = {
    group_scale = 1.2,

    h          = 1.1,                        min_w      = 2.2,
    max_w      = 3,                          anchor_cx  = 1.06,
    anchor_cy  = 0.94,
}

----------------------------------------------------------
--- mask & underlay (2nd pass)
----------------------------------------------------------
M.mask = {
    quad_key  = "btn3_mask",                 -- fit_axis  = "width",
    fit_axis  = _fit_axis,                   affects_layout = Y,

    --- detailed x, y,w, h
    x         = 0,                           y         = 0,
    w_scale   = 1.03,                        h_scale   = _h_scale,
    w_pad     = 0.1,                         h_pad     = 0,
    tint      = ck,
}

M.mask_underlay = {
    enabled   = Y,
    quad_key  = "btn3_mask",                 -- fit_axis  = "width",
    fit_axis  = _fit_axis,

    x         = -0.05,                       y         = -0.05,
    w_scale   = 1.07,                        h_scale   = _h_scale,
    w_pad     = 0.1,                         h_pad     = 0.11,
    tint      = cpaper,                     --  paint     = { shader = "paper_sway", speed = 0.5 },
}

-------------------------------------------------------------
--- frame sprites placement
-------------------------------------------------------------
M.frame = {
    base_w = 2.12,                         base_h = 1.1,

    --- top related
    top_left     = { quad_key = "btn3_type1_top_left",     x            =  0.07,     y      = _top_sink,            scale    = 0.91 },
    top_right    = { quad_key = "btn3_type1_top_right",    gap          = 0.37,      y      = _top_sink - 0.07,     w_ratio  = 0.24 },
    fold = {
        quad_key  = "btn3_type1_fold",     fit_axis  = "none",
        gap       = 0.11,                  y         = _top_sink - 0.01,
        w_ratio   = 0.19,                  -- wh_ratio  = 0.8,
        w_scale   = 1,                     h_scale   = 0.5,
    },

    --- right edge
    right        = { quad_key = "btn3_type1_right",        gap          = 0.145,      y         = 0.17,             h_ratio = 0.54,  wh_ratio = 0.38, scale = 0.9 },

    --- bottom_related
    bottom_left  = { quad_key = "btn3_type1_bottom_left",  x            = 0.08,      gap_y  = _bottom_raise + 0.05,      w_ratio  = 0.15 },
    bottom       = { quad_key = "btn3_type1_bottom",       x_shift      = 0.25,      gap_y  = _bottom_raise,             w_extra  = 0.0,    scale = 0.91 },  -- gap_y: how much to raise from bottom
    bottom_right = { quad_key = "btn3_type1_bottom_right", gap          = 0.1,       gap_y  = _bottom_raise - 0.01,      w_ratio  = 0.24 }, -- gap:   how much to shift from right

    anchor       = { quad_key = "btn1_pinch",              x            = 0.77,      y      = 0.96,                       w       = 0.58, right_gap = 0.72 },
}

-------------------------------------------------------------
--- label & colors of actual contents
-------------------------------------------------------------
M.defaults = {
    --- text related
    label_text_scale  = 0.26,                label_min_text_scale  = 0.20,
    font_type         = HintText.font_type,  text_line_spacing     = HintText.line_spacing,

    --- icon related
    icon_x            = 0.18,                icon_y                = 0.27,
    icon_w            = 0.34,                label_gap             = 0.16,
    right_pad         = 0.02,

    --- color settings
    mask_tint         = ck,                  frame_tint            = cpaper,
    icon_tint         = cpaper,              icon_hover_color      = co,
    label_color       = ctl,                 label_hover_color     = co,
    anchor_tint       = cpaper,
}

return M
