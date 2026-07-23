local C, CUtils      = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local HintText       = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.hint_btn_cfg.hint_text_cfg")
local PaintSeeds     = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.folded_btn_type4_paint_seeds")

local CTTL,   CUI    = C.TITLE,    C.UI
local ck,     co     = C.BLACK,    C.ORANGE
local cw,     ccrm   = C.WHITE,    C.CREAM
local cpaper, ctl    = CTTL.PAPER, CUI.TEXT_LIGHT

local _bottom_raise  = 0.32
local _top_sink      = 0.05

local Y, N = true, false

local M = {}

-----------------------------------------------------------
--- base & layout
----------------------------------------------------------
M.base = {
    type          = "type4",             label_suffix  = "_label",
    shadow_layer  = 1,                   face_layer    = 2,
}

M.layout = {
    group_scale = 1,

    h          = 1.02,                   min_w      = 2.12,
    max_w      = 4.80,                   anchor_cx  = 1.06,
    anchor_cy  = 0.94,
}

-------------------------------------------------------------
--- paint-rect body
-------------------------------------------------------------
M.bg = {
    style       = "paint_rect",          x        = 0,
    y           = 0,                     base_w   = 0.8,
    base_h      = 0.15,                  h_extra  = 0,
    fill_color  = ck,                    shadow   = N,

    paint_seeds = PaintSeeds,            paint    = { shader = "_1_watercolor_edge" },
    paint_seed_index = 1,
}

M.bg_underlay = {
    enabled     = Y,                    
    
    x           = -0.05,                y          = -0.05,                    w_scale    = 1.04,
    h_scale     = 1.13,                 w_pad      = 0,
    h_pad       = 0,                    fill_color = cpaper,
    shadow      = N,
}

-------------------------------------------------------------
--- frame sprites placement
-------------------------------------------------------------
M.frame = {
    base_w = 2.12,                         base_h = 1.02,

    --- top related
    top_left     = { quad_key = "btn4_type1_top_left",     x            = 0.18,     y      = _top_sink + 0.07,  w_ratio = 0.14 },
    top          = { quad_key = "btn4_type1_top",          gap          = 1.2,      y      = _top_sink - 0.04,  w_ratio = 0.77, scale = 2 },
    top_right    = { quad_key = "btn4_type1_top_right",    gap          = 0.17,     y      = _top_sink + 0.05,  w_ratio = 0.14 },

    --- right edge
    right        = { quad_key = "btn4_tape_edge",          gap          = 0.6,      y      = -0.2,              h_ratio = 0.41, wh_ratio = 0.7, tint = ccrm },

    --- bottom related
    bottom_left  = { quad_key = "btn4_type1_bottom_left",  x            = 0.18,     gap_y  = _bottom_raise,     w_ratio = 0.16 },
    bottom       = { quad_key = "btn4_type1_bottom",       x_shift      = 0.75,     gap_y  = _bottom_raise - 0.04,     w_extra = 0.04,     scale = 1 },
    bottom_right = { quad_key = "btn4_type1_bottom_right", gap          = 0.17,     gap_y  = _bottom_raise,     w_ratio = 0.41 },

    anchor       = { quad_key = "btn1_pinch",              x            = 0.77,      y      = 1.01,      w = 0.58, right_gap = 0.72 },
}

-------------------------------------------------------------
--- label & colors of actual contents
-------------------------------------------------------------
M.defaults = {
    --- text related
    label_text_scale  = 0.26,                label_min_text_scale  = 0.20,
    font_type         = HintText.font_type,  text_line_spacing     = HintText.line_spacing,

    --- icon related
    icon_x            = 0.38,                icon_y                = 0.27,
    icon_w            = 0.34,                label_gap             = 0.16,
    right_pad         = 0.32,

    --- color settings
    bg_fill_color     = ck,                  bg_shadow             = N,
    frame_tint        = cw,                  icon_tint             = ccrm,
    icon_hover_color  = co,                  label_color           = ctl,
    label_hover_color = co,                  anchor_tint           = cpaper,
}

return M
