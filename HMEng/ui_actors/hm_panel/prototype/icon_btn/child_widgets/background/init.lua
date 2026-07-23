local child_widgets_dir = "HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background."

local Rbox       = require(child_widgets_dir .. "rbox")
local PaintRect  = require(child_widgets_dir .. "btn_bg_paint_rect")
local RoundRect  = require(child_widgets_dir .. "round_rect")

local Y, N = true, false

local M = {}

------------------------------------
--- build
------------------------------------
function M.build(id, args)
    local style = args.bg_style or "paint_rect"

    if args.bg_hover_edge == Y  then style = "paint_rect" end
    if style == "rbox"          then return Rbox.build(id, args) end
    if style == "paint_rect"    then return PaintRect.build(id, args) end
    if style == "round_rect"    then return RoundRect.build(id, args) end

    return PaintRect.build(id, args)
end

return M
