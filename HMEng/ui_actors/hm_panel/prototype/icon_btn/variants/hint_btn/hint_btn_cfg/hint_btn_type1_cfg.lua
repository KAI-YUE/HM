local C, CUtils  = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local HintText   = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.hint_btn_cfg.hint_text_cfg")

local tint_alpha = CUtils.tint_with_alpha

local CUI,    CTTL     = C.UI,           C.TITLE
local ctl,    cw       = CUI.TEXT_LIGHT, C.WHITE
local ccrm,   ck       = C.CREAM,        C.BLACK
local cpaper, cshadow  = CTTL.PAPER,     { 0, 0, 0, 0.32 }
local cface,  cunder   = tint_alpha(cw, 0.8), tint_alpha(cpaper, 0.8)
local tcrm = tint_alpha(ccrm, 0.8)

local Y, N = true, false

local M = {}

----------------------
--- base 
----------------------
M.base = {
    id        = "hint_btn",           type          = "hint_btn",
    renderer  = "hint_btn",           label_suffix  = "_label",
}

----------------------
--- hid 
----------------------
M.hid = {
    hid_action = "delete",
}

----------------------
--- hint behavior
----------------------
M.hint = {
    show_when        = "controller",    page_draw_layer  = "overlay",
    hover_tint       = 0,
}

----------------------
--- glyph: gamepad glyph
----------------------
M.glyph = {
    atlas_key  = "console_pack",        quad_key  = "x",
    fit_axis   = "width",               T         = { x = 0.14, y = 0.08, w = 0.4 },

    T_by_quad  = {
        pad_option = { x = 0.3,  y = 0.22, w = 0.42 },
        ps_options = { x = 0.3,  y = 0.22, w = 0.42 },
        triangle   = { x = 0.3,  y = 0.22, w = 0.4 },
        circle     = { x = 0.3,  y = 0.22, w = 0.4 },
        square     = { x = 0.3,  y = 0.218, w = 0.38 },
        cross      = { x = 0.3,  y = 0.22, w = 0.4 },
        A          = { x = 0.325, y = 0.235, w = 0.32 },
        B          = { x = 0.325, y = 0.235, w = 0.32 },
        x          = { x = 0.325, y = 0.235, w = 0.32 },
        Y          = { x = 0.325, y = 0.235, w = 0.32 },
    },

    --- color settings
    -- tint       = cw,
    tint = tcrm
}

----------------------
--- btn art
----------------------
M.btn = {
    atlas_key     = "console_pack",     tint          = cface,
    draw_order    = 2,                  shadow_layer  = 0,
    face_layer    = 2,
    T             = { x = 0.11, y = 0.06, w = 0.4 },
}

----------------------
--- mask_underlay
----------------------
M.mask_underlay = {
    atlas_key   = "console_pack",       tint        = cunder,
    draw_order  = 1,
}

M.mask_by_quad = {
    circle_shape_btn = { x = -0.036,  y = -0.016, w_pad = 0.072 },
    lb_btn           = { quad_key = "lb_btn_mask", x = -0.025, y = -0.015, w_pad = 0.072 },
    rb_btn           = { quad_key = "rb_btn_mask", x = -0.025, y = -0.015, w_pad = 0.072 },
    LT               = { quad_key = "LT_mask" },
    dpad             = { quad_key = "dpad_mask" },
}

----------------------
--- label
----------------------
M.label = {
    x          = 0.31,                  y             = 0.7,
    w          = 2.4,                   h             = 0.52,
    text       = "",                    text_scale    = HintText.text_scale,
    font_type  = HintText.font_type,    line_spacing  = HintText.line_spacing,
    color      = ctl,                   align         = { x = "left", y = "middle" },
}

----------------------
--- shadow
----------------------
M.shadow = {
    color     = cshadow,                parallax = { x = 1, y = -1.55 },
    btn       = Y,                      glyph    = N,
    mask      = N,
}

----------------------
--- debug_bg
----------------------
M.debug_bg = {
    x = -0.08,                          y = -0.08,
    w = 3.2,                            h = 0.68,
    color = { 1, 0, 0, 0.82 },          radius = 0.06,
}

return M
