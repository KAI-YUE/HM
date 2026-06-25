local C = require("HMfns.animate.color.color_const")

local Y, N = true, false

local M = {}

local chip_font_sampling = { ransom_sampling_rate = 0, ransom_numbers = N, normal = { Gsans_small_textfx = 1 } }
local default_text_bg = { color = C.WHITE, sx = 0.49, ox = -0.4, oy = -0.2, shader = "_-4_watercolor_slot_wipe", slot_enter_shader = "_1_watercolor_edge", fx_mask_ref = "fx_mask", fx_mask_dir_ref = "fx_mask_dir" }

--- Helper: text_bg_cfg
local function text_bg_cfg(bg)
    local out = {}
    for k, v in pairs(default_text_bg) do out[k] = v end
    for k, v in pairs(bg or {}) do out[k] = v end
    return out
end

--- Helper: textfx
function M.textfx(text, T, args)
    args = args or {}
    return {         T = T,
        text           = tostring(text or ""),                   textfx_seed         = args.textfx_seed,
        sampling_seed  = args.sampling_seed,
        text_scale     = args.text_scale or 0.3,                 text_align           = args.text_align or { x = "left", y = "middle" },
        textfx_static  = args.textfx_static ~= N,                text_bg              = text_bg_cfg(args.text_bg),

        button         = N,                                      fx_mask_shader      = args.fx_mask_shader or args.shader or "_-3_slot_wipe",
        slot_enter_delay = args.slot_enter_delay,                disable_rotation    = args.disable_rotation ~= N,
        letter_paper   = N,                                      card_font_sampling  = args.card_font_sampling or chip_font_sampling,
        card_paper_color = args.card_paper_color or C.WHITE,
        card_text_color  = args.card_text_color  or C.BLACK,
    }
end

return M
