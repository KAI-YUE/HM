local I18N = require("HMfns.utils.format.i18n_utils")

local i18n = I18N.i18n

local M = {}

--- Helper: sab_lang | system_text
function M.sab_lang(gm) return { key = "sab", font_type = "SAB", font = gm and gm.g_fonts and gm.g_fonts.SAB } end
function M.system_text(gm, key, fallback) local text = i18n(gm, { type = "menu", key = "options.system." .. key }); return text or fallback end

--- Helper: base_args
function M.base_args(gm, entry)
    return {
        id                         = "system_" .. entry.key,
        label                      = M.system_text(gm, entry.label_key or entry.key, entry.fallback or entry.key),
        lang                       = gm.selected_lang,
        tile_size                  = gm.rcfg.tile_size,
        description_key            = entry.description_key,
        finish_reveal_b4_fade      = entry.finish_reveal_b4_fade,
        hover_dwell_by_text_speed  = entry.hover_dwell_by_text_speed,
        description_lang           = entry.description_font_type == "SAB" and M.sab_lang(gm) or entry.description_lang,
        i18n_scope                 = entry.i18n_scope or "options.system.descriptions",
    }
end

return M
