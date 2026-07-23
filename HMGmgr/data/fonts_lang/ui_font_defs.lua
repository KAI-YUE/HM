local M = {}

--- Helper: ui_font
--- render_scale_mult controls raster font size: lower it for tiny UI labels to reduce downscale aliasing.
--- font_scale is per-font visual calibration; it is not card_textfx char_scale.
function M.ui_font(name, render_scale_mult, font_scale, opts)
    opts = opts or {}
    return { name = opts.name or name, file = name, render_scale = function(tz) return (render_scale_mult or 2)*tz end, font_scale = font_scale or 0.4, font_hl_scale = opts.font_hl_scale, font_offset = opts.font_offset, squish = opts.squish }
end

local _ui_font = M.ui_font
local _small_ui_render_scale, _small_ui_font_scale = 1.5, 0.8/1.5

M.Gsans_hint = _ui_font("Gsans", 1, 1, { name = "Gsans_hint" })
M.SAB_hint   = _ui_font("SAB",   1, 1, { name = "SAB_hint" })

M.ZCOOLXW_small_ui      = _ui_font("ZCOOLXW",      _small_ui_render_scale, _small_ui_font_scale, { name = "ZCOOLXW_small_ui" })
M.Gsans_small_ui        = _ui_font("Gsans",        _small_ui_render_scale, _small_ui_font_scale, { name = "Gsans_small_ui" })
M.HachiMaruPop_small_ui = _ui_font("HachiMaruPop", _small_ui_render_scale, _small_ui_font_scale, { name = "HachiMaruPop_small_ui" })
M.SAB_small_ui          = _ui_font("SAB",          _small_ui_render_scale, _small_ui_font_scale, { name = "SAB_small_ui" })

return M
