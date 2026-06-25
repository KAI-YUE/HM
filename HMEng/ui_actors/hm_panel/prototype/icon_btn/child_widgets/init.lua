local Background  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background")
local Icon        = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.icon")
local Dots        = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.dots")
local Label       = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.label")
local HoverArrow  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.hover_arrow")

local M = {}

function M.build(args)
    local id, out = args.id or "icon_btn", {}
    out[#out + 1] = Background.build(id, args)
    out[#out + 1] = Icon.build(id, args)

    for _, dot in ipairs(Dots.build(id, args)) do
        out[#out + 1] = dot
    end

    out[#out + 1] = Label.build(id, args)
    if args.hover_arrow ~= false then out[#out + 1] = HoverArrow.build(id, args) end
    return out
end

return M
