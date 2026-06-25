local C = require("HMfns.animate.color.color_const")

local Y, N = true, false

local M = {}

local ccrm, ctl, ctd = C.CREAM, C.UI.TEXT_LIGHT, C.UI.TEXT_DARK

local dummy_ransom_font_sampling = {
    ransom_sampling_rate = 1,
    ransom_numbers = N,
    max_allowable_fonts = 3,
    normal = {
        SAB_Panel_textfx = 1,
        -- ZCOOLXW_Panel_textfx = 1,
    },
}

--- Helper: max_succ_ransom
local function max_succ_ransom(ctx)
    local max_succ = tonumber(ctx.config and ctx.config.max_succ_ransom)
    if not max_succ or max_succ < 1 then return end
    return math.floor(max_succ)
end

--- Helper: succ_style_count
local function succ_style_count(cache, key)
    local count = 0
    for i = #(cache and cache.letters or {}), 1, -1 do
        if cache.letters[i].letter_style_key ~= key then break end
        count = count + 1
    end
    return count
end

--- Helper: dummy_ransom_dark
local function dummy_ransom_dark(ctx)
    local dark = ctx.unit("dummy_ransom_text_color") < 0.5
    local max_succ = max_succ_ransom(ctx)
    if max_succ and succ_style_count(ctx.cache, dark and "dark_cream" or "light_none") >= max_succ then dark = not dark end
    return dark
end

--- Helper: letter_style
local function letter_style(_, ctx)
    local dark = dummy_ransom_dark(ctx)
    local style = {
        letter_style_key = dark and "dark_cream" or "light_none",
        text_color = dark and ctd or ctl,
        paper_color = ccrm,
        letter_bg_o_px = -0.1,
        letter_bg_o_py = -0.1,
        letter_s_pw = 3.7,
        letter_s_ph = 1.7,
    }
    if not dark then style.letter_paper = N end
    return style
end

---____________________________
--- main: textfx
---______________________________________
function M.textfx(text, T, args)
    args = args or {}
    return { T           = T,
        text             = tostring(text or ""),                    textfx_seed         = args.textfx_seed,
        sampling_seed    = args.sampling_seed,
        text_scale       = args.text_scale or 0.7,                  text_align          = args.text_align or { x = "left", y = "middle" },
        text_bg          = N,                                       button              = N,

        --- background settings
        textfx_static    = args.textfx_static ~= N,                 fx_mask_shader      = args.fx_mask_shader or args.shader or "_-3_slot_wipe",
        letter_paper     = args.letter_paper or { color = ccrm },   card_font_sampling  = args.card_font_sampling or dummy_ransom_font_sampling,

        --- transform settings
        disable_rotation = args.disable_rotation ~= N,              letter_style_fn     = args.letter_style_fn or letter_style,
        disable_ransom_scale = args.disable_ransom_scale ~= N,      disable_ransom_offset = args.disable_ransom_offset ~= N,
        disable_letter_bg_shader = args.disable_letter_bg_shader ~= N,
        max_succ_ransom = args.max_succ_ransom == nil and 2 or args.max_succ_ransom,
    }
end

return M
