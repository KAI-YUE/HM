local I18N = require("HMfns.utils.format.i18n_utils")

local i18n = I18N.i18n

local M = {}

--- Helper: audio_text
function M.audio_text(gm, key, fallback)
    local text = i18n(gm, { type = "menu", key = "options.audio." .. key })
    if not text or text == "ERROR" then return fallback end
    return text
end

--- Helper: base_args
function M.base_args(gm, entry)
    return {
        id                         = "audio_" .. entry.key,
        label                      = M.audio_text(gm, entry.label_key or entry.key, entry.fallback or entry.key),
        lang                       = gm.selected_lang,
        tile_size                  = gm.rcfg.tile_size,
        description_key            = entry.description_key,
        finish_reveal_b4_fade      = entry.finish_reveal_b4_fade,
        hover_dwell_by_text_speed  = entry.hover_dwell_by_text_speed,
        description_lang           = entry.description_lang,
        i18n_scope                 = entry.i18n_scope or "options.audio.descriptions",
    }
end

return M
