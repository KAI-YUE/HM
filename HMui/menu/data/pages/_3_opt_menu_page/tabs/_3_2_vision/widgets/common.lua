local I18N = require("HMfns.utils.format.i18n_utils")

local i18n = I18N.i18n

local M = {}

--- Helper: sab_lang | vision_text
function M.sab_lang(gm) return { key = "sab", font_type = "SAB", font = gm and gm.g_fonts and gm.g_fonts.SAB } end
function M.vision_text(gm, key, fallback) local text = i18n(gm, { type = "menu", key = "options.vision." .. key }); return text or fallback end

--- Helper: auto_option
function M.auto_option(gm) return { key = "auto", value = "auto", label = M.vision_text(gm, "auto", "Auto") } end

--- Helper: base_args
function M.base_args(gm, entry)
    return {
        id                         = "vision_" .. entry.key,
        label                      = M.vision_text(gm, entry.label_key or entry.key, entry.fallback or entry.key),
        lang                       = gm.selected_lang,
        tile_size                  = gm.rcfg.tile_size,
        description_key            = entry.description_key,
        finish_reveal_b4_fade      = entry.finish_reveal_b4_fade,
        hover_dwell_by_text_speed  = entry.hover_dwell_by_text_speed,
        description_lang           = entry.description_lang,
        i18n_scope                 = entry.i18n_scope or "options.vision.descriptions",
    }
end

return M
