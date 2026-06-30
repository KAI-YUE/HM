local C, CUtils  = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local TabUtils   = require("HMfns.utils.table_utils")

local lerp_color   = CUtils.lerp_colors
local tint_alpha   = CUtils.tint_with_alpha
local rand         = math.random
local random_pick  = TabUtils.random_pick

local _ccard    = C.CARD
local cbase     = _ccard.BASE
local ccrm, cw  = C.CREAM, C.WHITE

local M = {}

--- Helper: sample range
local function _sample_range(range, fallback)
    if type(range) ~= "table" then return fallback end
    local a, b = range[1] or fallback, range[2] or range[1] or fallback
    return a + (b - a)*rand()
end

-----------------------------
--- frame presets
----------------------------
M.frames = {
    default = {
        frame_key     = "card_frame_1",   frame_scale = 0.95,
        frame_scale_x = 0.95,             frame_scale_y = 0.95,
        frame_x       = 0,                frame_y       = 0,
    },

    alt = {
        frame_key     = "card_frame_2",   frame_scale = 1.0,
        frame_scale_x = 1.0,              frame_scale_y = 1.0,
        frame_x       = 0,                frame_y       = 0,
    },
}

-----------------------------
--- base presets
----------------------------
M.base = {
    default = {
        base_color = _ccard.BASE,
    },
}

-----------------------------
--- main: card front preset
----------------------------
M.default = {
    base_color      = cbase,               base_tint_color = cw,
    base_tint_range = { 0.02, 0.3 },

    --- frame setting 
    valid_frames     = { "card_frame_1", "card_frame_2" },
    frame_key        = "card_frame_1",     frame_scale   = 0.95,  -- shared fallback
    frame_scale_x    = 0.95,               frame_scale_y = 0.97,
    frame_x          = 0,                  frame_y       = -0.0045,
    frame_alpha      = 0.2,                frame_alpha_range = { 0.1, 0.2 },
}

--------------------------------
--- random_base_color
--------------------------------
function M.random_base_color(cfg)
    cfg = cfg or M.default
    local p = _sample_range(cfg.base_tint_range, 0.4)
    return lerp_color(cfg.base_color or cbase, cfg.base_tint_color or ccrm, p)
end

--------------------------------
--- frame_color 
--------------------------------
function M.frame_color(suit_color, cfg)
    cfg = cfg or M.default
    return tint_alpha(suit_color, _sample_range(cfg.frame_alpha_range, cfg.frame_alpha or 0.5))
end

--------------------------------
--- frame_key
--------------------------------
function M.frame_key(cfg) cfg = cfg or M.default; return random_pick(cfg.valid_frames) or cfg.frame_key or "card_frame_1" end

return M
