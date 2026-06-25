local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local M = {}

---____________________________
--- main: set_draw_alpha
---______________________________________
function M.set_draw_alpha(widget, alpha)
    if widget.draw_alpha == nil then return end
    widget.page_switch_draw_alpha = widget.page_switch_draw_alpha or widget.draw_alpha
    widget.draw_alpha = alpha
end

---____________________________
--- main: fade_draw_alpha
---______________________________________
function M.fade_draw_alpha(gm, widget, alpha, delay)
    if widget.draw_alpha == nil then return end
    widget.page_switch_draw_alpha = widget.page_switch_draw_alpha or widget.draw_alpha
    Common.ease(gm, widget, "draw_alpha", alpha, delay)
end

---____________________________
--- main: target_draw_alpha
---______________________________________
function M.target_draw_alpha(widget) return widget.page_switch_draw_alpha or widget.draw_alpha end

return M
