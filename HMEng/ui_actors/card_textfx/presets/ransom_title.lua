local Y, N = true, false

local M = {}

-----------------------------
--- use case
----------------------------
--- Large cut-paper ransom title for primary save-slot names, such as DATA 1.
--- Looks like mixed magazine letters with occasional normal-font glyphs.
--- Use when the text should be the loud readable headline of the card.

local ransom_title_font_sampling = {
    ransom_sampling_rate = 1,
    ransom_numbers = Y,
    max_allowable_fonts = 2,
    ransom = {
        ransom1_textfx = 1,
        ransom2_textfx = 1,
        ransom3_textfx = 1,
        ransom4_textfx = 1,
        ransom5_textfx = 1.5,
    },
    normal = {
        Gsans_textfx = 1,
        HachiMaruPop_textfx = 0.85,
        SAB_textfx = 1,
        ZCOOL_textfx = 0.3,
        ZCOOLXW_textfx = 1,
    },
}

--- Helper: textfx
function M.textfx(text, T, args)
    args = args or {}
    return { T           = T,
        text             = tostring(text or ""),             textfx_seed         = args.textfx_seed,
        sampling_seed    = args.sampling_seed,
        text_scale       = args.text_scale or 0.7,           text_align          = args.text_align or { x = "left", y = "middle" },
        text_bg          = args.text_bg or N,                button              = N,
        textfx_static    = args.textfx_static ~= N,          fx_mask_shader      = args.fx_mask_shader or args.shader or "_-3_slot_wipe",
        letter_paper     = args.letter_paper or N,           card_font_sampling  = args.card_font_sampling or ransom_title_font_sampling,
        disable_rotation = args.disable_rotation ~= N,
    }
end

return M
