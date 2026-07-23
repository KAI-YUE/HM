local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local ctd = Common.ctd
local N = false

local M = {}

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local text = args.label or "LOG"
    return {
        --- basics
        style  = "text_widget",                        T = { x = args.label_x or 1.02, y = args.label_y or 0.15, w = args.label_w or 0.68, h = args.label_h or 0.38, },
        id     = Common.child_id(id, "label"),

        --- hit settings
        button     = N,                                can_hover  = N,
        can_click  = N,                                can_drag   = N,

        --- text settings
        text = text,                                   text_scale = args.label_text_scale or 0.34,
        lang = args.label_lang,                        font_type = args.label_font_type,
        text_i18n_type = args.label_i18n_type,         text_i18n_scope = args.label_i18n_scope,
        text_i18n_key = args.label_i18n_key,           text_i18n_fallback = args.label_i18n_fallback,
        text_color = args.label_color or ctd,          idle_text_color = args.label_idle_color,
        text_shadow = args.label_shadow ~= N,
        hover_color = args.label_hover_color,          parent_hover_tint = args.label_parent_hover_tint ~= N,
        text_align = args.label_align or { x = "left", y = "middle" },
        text_padding  = args.label_padding or { x = 0, y = 0 }, text_offset = args.label_text_offset,
        text_maxw     = args.label_maxw or 3,          text_line_spacing = args.label_text_line_spacing,
    }
end

return M
