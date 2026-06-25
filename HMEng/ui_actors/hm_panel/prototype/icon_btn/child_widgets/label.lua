local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local ctd = Common.ctd
local N = false

local M = {}

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local text = args.label or args.text or "LOG"
    return {
        --- basics
        style  = "text_widget",                        T = { x = args.label_x or 1.02, y = args.label_y or 0.15, w = args.label_w or 0.68, h = args.label_h or 0.38, },
        id     = Common.child_id(id, "label"),

        --- hit settings
        button     = N,                                can_hover  = N,
        can_click  = N,                                can_drag   = N,

        --- text settings
        text = text,                                   text_scale = args.label_text_scale or 0.34,
        text_color = args.label_color or ctd,          text_shadow = args.label_shadow ~= N,
        hover_color = args.label_hover_color,          parent_hover_tint = args.label_parent_hover_tint ~= N,
        text_align = args.label_align or { x = "left", y = "middle" },
        text_padding  = args.label_padding or { x = 0, y = 0 },
        text_maxw     = args.label_maxw or args.text_maxw or 3,
    }
end

return M
