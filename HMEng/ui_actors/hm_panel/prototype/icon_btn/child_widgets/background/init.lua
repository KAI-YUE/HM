local Rbox      = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background.rbox")
local PaintRect = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background.btn_bg_paint_rect")
local RoundRect = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background.round_rect")

local M = {}

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local hover_edge = args.bg_hover_edge == true or args.hover_edge == true
    local style = args.bg_style or (args.bg_paint_rect and "paint_rect") or (hover_edge and "paint_rect") or (args.bg_round_rect and "round_rect") or "paint_rect"
    if style == "rbox" then return Rbox.build(id, args) end
    if style == "paint_rect" then return PaintRect.build(id, args) end
    if style == "round_rect" then return RoundRect.build(id, args) end
    return PaintRect.build(id, args)
end

return M
