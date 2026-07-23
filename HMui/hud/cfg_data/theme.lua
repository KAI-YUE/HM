local C = require("HMfns.animate.color.color_const")

local CHUD       = C.HUD
local cw,  cel   = C.WHITE,   CHUD.LIGHT_EDGE
local chk, ccrm  = CHUD.DARK, C.CREAM
local chb        = CHUD.BLUE_THEME
local cshdw      = { 0, 0, 0, 0.28 }

local Y, N = true, false

local M = {}

M.clear = C.CLEAR

-----------------------------
--- panel
-----------------------------
M.panel = {
    --- basic colors
    pass_tint   = cel,     base_tint   = cw,      -- pass_tint is for the underlying white-ish shadow 

    --- shadow
    shadow      = Y,        shadow_color = cshdw,
    widget_dist = 1.25,     shadow_parallax = { x = 0.08, y = -1.15 },
}

-----------------------------
--- profile
-----------------------------
M.profile = {
    stroke = {
        player = { back = chb,    front = chb },
        foe    = { back = C.RED,  front = C.RED },
    },
    stroke_shadow = {
        enabled = Y, color = cshdw, widget_dist = 1, order = "per_stroke",
        shadow_parallax = { x = 0.08, y = -1 },
    },
    -- icon = {
    --     player = "chef_hat",
    --     foe    = "chat",
    -- },
}

return M
