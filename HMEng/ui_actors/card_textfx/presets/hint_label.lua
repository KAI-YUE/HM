local C, CUtils   = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local PaintSeeds  = require("HMEng.ui_actors.card_textfx.presets.hint_label_paint_seeds")

local _tint_alpha = CUtils.tint_with_alpha

local _tbg = _tint_alpha(C.STEEL, 0.98)

local Y, N = true, false

local M = {}

-----------------------------
--- use case
-----------------------------
--- Compact SAB-only hint label with a native watercolor text background.
--- Use for small control labels that must stay stable across repeated draws.

local hint_label_font_sampling  = { ransom_sampling_rate = 0,  ransom_numbers = N, normal = { SAB_hint = 1 } }
local default_text_bg           = { color = _tbg,              widget_dist = 1, sx = 0.4, sy = 0.1, ox = -0.05, oy = -0.16, shader = "_1_watercolor_edge", shadow = N }
local default_text_offset       = { x = 0, y = 0 }

--- Helper: text_bg_cfg
local function text_bg_cfg(bg)
    local out = {}
    for k, v in pairs(default_text_bg) do out[k] = v end
    for k, v in pairs(bg or {}) do out[k] = v end
    return out
end

---______________________________________
--- main: textfx
---______________________________________
function M.textfx(text, T, args)
    args = args or {}

    local text_bg = text_bg_cfg(args.text_bg)
    local random_rotation, random_scale  = args.random_rotation == Y, args.random_scale == Y
    local random_offset,   random_flip   = args.random_offset == Y,   args.random_flip == Y

    if args.text_bg_color               then text_bg.color             = args.text_bg_color end
    if args.text_bg_widget_dist ~= nil  then text_bg.widget_dist       = args.text_bg_widget_dist end
    if args.text_bg_shadow ~= nil       then text_bg.shadow            = args.text_bg_shadow end
    if args.fx_mask_ref                 then text_bg.fx_mask_ref       = args.fx_mask_ref end
    if not text_bg.paint_seed_entry     then text_bg.paint_seed_entry  = PaintSeeds[args.paint_seed_index or 1] or PaintSeeds[1] end

    return {
        --- basics
        T                       = T,
        text                    = tostring(text or ""),
        button                  = N,

        --- text layout
        text_scale              = args.text_scale or 0.32,
        text_align              = args.text_align or { x = "left", y = "middle" },
        text_offset             = args.text_offset or default_text_offset,

        --- deterministic textfx
        textfx_seed             = args.textfx_seed,
        sampling_seed           = args.sampling_seed,
        textfx_static           = not random_flip,
        letter_flip             = random_flip,
        textfx_hover_event      = random_flip,
        textfx_jitter_guard     = random_offset,
        disable_rotation        = not random_rotation,
        disable_ransom_scale    = not random_scale,
        disable_ransom_offset   = not random_offset,

        --- font and color
        letter_paper            = N,
        card_font_sampling      = hint_label_font_sampling,
        card_text_color         = args.card_text_color or C.UI.TEXT_LIGHT,
        text_shadow             = N,
        fx_mask_shader          = args.fx_mask_shader,

        --- paint background
        text_bg                 = text_bg,
        shadow                  = args.shadow ~= N,
    }
end

M.paint_seeds = PaintSeeds

return M
