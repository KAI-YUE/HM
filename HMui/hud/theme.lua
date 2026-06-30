local C = require("HMfns.animate.color.color_const")

local CHUD = C.HUD
local cw = C.WHITE
local chk, ccrm = CHUD.DARK, C.CREAM
local chb    = CHUD.BLUE_THEME
local cshdw  = { 0, 0, 0, 0.28 }
local cdenim = { 0.24, 0.43, 0.56, 0.92 }

local Y, N = true, false

local M = {}

M.clear = C.CLEAR

-----------------------------
--- panel
-----------------------------
M.panel = {
    --- basic colors
    pass_tint   = ccrm,     base_tint   = chk,      -- pass_tint is for the underlying white-ish shadow 
    detail_tint = chk,

    --- shadow
    shadow      = Y,        shadow_color = cshdw,
    widget_dist = 1.25,     shadow_parallax = { x = 0.08, y = -1.15 },

    --- seam
    seam_tint   = cdenim,   seam_animate = N,
    seam_speed  = 5,
}

-----------------------------
--- profile
-----------------------------
M.profile = {
    stroke = {
        player = { back = chb,    front = chb },
        foe    = { back = C.RED,    front = C.RED },
    },
    stroke_shadow = {
        enabled = Y, color = cshdw, widget_dist = 1, order = "per_stroke",
        shadow_parallax = { x = 0.08, y = -1 },
    },
    icon = {
        player = "chef_hat",
        foe    = "chat",
    },
}

-----------------------------
--- icons
-----------------------------
M.icons = {
    hp    = "heart",
    full  = "muffin",
    money = "coin",
}

-----------------------------
--- bars
-----------------------------
M.bar_bg = {
    hp   = { 1, 1, 1, 0.46 },
    full = { 1, 1, 1, 0.46 },
}

M.bars = {
    hp   = { fill = C.RED,   bg = { 0.08, 0.07, 0.06, 0.72 }, line = { 1, 1, 1, 0.18 } },
    full = { fill = C.GREEN, bg = { 0.08, 0.07, 0.06, 0.72 }, line = { 1, 1, 1, 0.18 } },
}

return M
