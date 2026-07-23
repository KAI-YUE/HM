local C = require("HMfns.animate.color.color_const")

local CHUD  = C.HUD
local chred,  chbrn = CHUD.STATUS_HP_RED, CHUD.STATUS_FULL_BROWN
local chbag,  crd   = CHUD.STATUS_MBAG,   C.RED
local cw,     ccrm  = C.WHITE, C.CREAM

local row1_y, _gap    = 0.75,        0.8
local row2_y, row3_y  = 0.45 + _gap, 0.45 + 2*_gap
local icon_x, bar_x   = 3,           3.6
local bar_h,  body_h  = 0.12,        0.082
local _y_gap, bar_w   = 0.12,        2.1
local _overlap = 0.1

local M = {}

-------------------------------------------
--- icons
-------------------------------------------
M.icons = {
    hp    = { x = icon_x, y = row1_y,     w = 0.36, fit_axis = "width" },
    full  = { x = icon_x, y = row2_y,     w = 0.5, fit_axis = "width" },
    money = { x = icon_x, y = row3_y-0.2, w = 0.36, fit_axis = "width" },
}
-- M.icon_pass = { x = -0.035, y = -0.035, w_pad = 0.07, h_pad = 0.07, wh_ratio = nil }
M.icon_style = {
    hp    = { atlas_key = "icon_pack", quad_key = "heart",           tint = crd, pass = { tint = ccrm, x = -0.035, y = -0.055, w_pad = 0.07, h_pad = 0.1, wh_ratio = 0.97 } },
    full  = { atlas_key = "icon_pack", quad_key = "bread_mask",      tint = chbrn, pass = { quad_key = "bread", tint = ccrm } },
    money = { atlas_key = "hud_pack",  quad_key = "money_bag_mask",  tint = chbag, pass = { quad_key = "money_bag", tint = ccrm } },
}

-------------------------------------------
--- bars 
-------------------------------------------
M.bars = {
    { key = "hp",   x = bar_x, y = row1_y + _y_gap, h = bar_h, body_h = body_h, fit_axis = "height", body_w = bar_w, cap_overlap = _overlap, pad = 0.0, fill = crd,      },
    { key = "full", x = bar_x, y = row2_y + _y_gap, h = bar_h, body_h = body_h, fit_axis = "height", body_w = bar_w, cap_overlap = _overlap, pad = 0.0, fill = C.GREEN, },
}

return M
