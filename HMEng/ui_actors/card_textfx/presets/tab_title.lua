local C          = require("HMfns.animate.color.color_const")
local CUtils     = require("HMfns.animate.color.color_utils")
local IconCross  = require("HMEng.visual.hover_fx.icon_cross")

local lerp_colors = CUtils.lerp_colors
local tint_alpha  = CUtils.tint_with_alpha

local ck, ccrm = C.BLACK, C.CREAM
local ctl      = C.UI.TEXT_LIGHT
local tstroke  = tint_alpha(ccrm, 0.93)

local Y, N = true, false

local M = {}

local tab_title_font_sampling = {  ransom_sampling_rate       = 0.44, avoid_successive_ransom    = Y,
    normal = { Gsans_textfx = 1 },  ransom = { ransom1_textfx = 1, ransom2_textfx = 1 },
}

local tactive_text  = ctl
local tidle_text    = lerp_colors(tactive_text, ck, 0.58)
local tactive_bleed = ck
local tidle_bleed   = lerp_colors(tactive_bleed, ck, 0.56)

local tab_paint_seed_entries = {
    opt_audio   = { seed = 2314503, x_mul = 0.05, y_mul = 0.7, w_mul = 2.55, h_mul = 6.8, wobble = 0.3, bleed = 0.5,  feather_px = 0.1 },
    opt_vision  = { seed = 566562,  x_mul = 0.05, y_mul = 0.7, w_mul = 2.55, h_mul = 6.5, wobble = 0.2, bleed = 0.5,  feather_px = 0.1 },
    opt_control = { seed = 550851,  x_mul = 0.05, y_mul = 0.7, w_mul = 2.8,  h_mul = 6.5, wobble = 0.2, bleed = 0.4,  feather_px = 2 },
    opt_system  = { seed = 574719,  x_mul = 0.05, y_mul = 0.7, w_mul = 2.55, h_mul = 6.5, wobble = 0.3, bleed = 0.4,  feather_px = 3 },
}

--- Helper: text_bg_cfg
local function text_bg_cfg(tab, selected) return { color = selected and tactive_bleed or tidle_bleed } end

---____________________________
--- main: textfx
---______________________________________
function M.textfx(tab, args)
    args = args or {}
    local selected     = args.selected == Y
    local interactive  = args.interactive ~= N
    local active_text  = args.card_text_color or tactive_text
    local idle_text    = args.idle_text_color or tidle_text
    return {
        --- basic key + description settings
        key = tab.key,                 text_i18n_key = tab.text_i18n_key,       description_key = tab.description_i18n_key,

        --- position settings
        x = tab.x or 0,                 y = tab.y or 0,                         r = tab.r or 0,
        room_ref = Y,

        --- hit settings
        shadow = Y,                    button = interactive,                    hook_fn = interactive and (args.hook_fn or "opt_tab_switch") or nil,
        can_hover = interactive,       can_click = interactive,
        gamepad_focus = args.gamepad_focus,
        options_tab_key = tab.key,

        --- text settings
        textfx_static = N,             text_align = { x = "center", y = "middle" }, letter_flip = selected and nil or N,
        disable_rotation = Y,          card_font_sampling = args.card_font_sampling or tab_title_font_sampling,

        --- color setting
        card_text_color = selected and active_text or idle_text,
        textfx_alpha = 1,

        --- option specific settings
        options_tab_visual_state = selected and "selected" or "idle",   options_tab_color_state = selected and "hover" or "idle",
        options_tab_text_color   = active_text,                         options_tab_idle_text_color = idle_text,
        options_tab_bleed_color = tactive_bleed,                        options_tab_idle_bleed_color = tidle_bleed,

        --- background, hint
        text_bg = text_bg_cfg(tab, selected),                           text_hint = N,
        textfx_hover_event = interactive and selected and Y or N,

        --- hover icon
        hover_icons = interactive and not selected and (args.hover_icons or IconCross.instance("fork_knife", { color = tstroke })),

        --- sampling_seed settings
        textfx_seed   = tab.textfx_seed or args.textfx_seed,
        sampling_seed = tab.sampling_seed or args.sampling_seed,
        sampling_seed_list = tab.sampling_seed_list or args.sampling_seed_list,
        paint_seed_entry = tab.paint_seed_entry or args.paint_seed_entry or tab_paint_seed_entries[tab.key],
    }
end

return M
