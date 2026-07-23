local C = require("HMfns.animate.color.color_const")

local ck, co = C.BLACK, C.ORANGE
local cw, ccrm = C.WHITE, C.CREAM
local ctl = C.UI.TEXT_LIGHT

local M = {}

M.base = {
    w = 2.12,                h = 1.02,
    anchor_cx = 1.06,        anchor_cy = 0.94,
    label_suffix = "_label",
    shadow_layer = 1,        face_layer = 2,
}

M.parts = {
    mask   = { atlas_key = "inter_btn_pack",      quad_key = "btn1_mask",      T = { x = 0,     y = 0,     w = 2.08 }, tint = ck },
    frame  = { atlas_key = "inter_btn_pack",      quad_key = "btn1_out_frame", T = { x = -0.08, y = -0.08, w = 2.28 }, tint = cw },
    icon   = { atlas_key = "card_pawn_icon_pack", quad_key = "hold_one",       T = { x = 0.18,  y = 0.14,  w = 0.34 }, tint = ccrm, hover_color = co },
    anchor = { atlas_key = "inter_btn_pack",      quad_key = "btn1_pinch",     T = { x = 0.77,  y = 0.82,  w = 0.58 }, tint = cw },
}

M.label = {
    T = { x = 0.82, y = 0.36, w = 0.92, h = 0.26 },
    text_scale = 0.26,     text_color = ctl,
    hover_color = co,      text_maxw = 1.4,
    align = { x = "center", y = "middle" },
    padding = { x = 0, y = 0 },
}

return M
