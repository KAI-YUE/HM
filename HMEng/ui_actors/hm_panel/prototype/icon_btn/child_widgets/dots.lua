local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local tint_alpha = Common.tint_alpha
local ctd = Common.ctd

local M = {}

local _dot_x, _dot_y = 0.91, 0.1
local _dot_gap = 0.15

--- Helper: dot_child
local function _dot_child(id, i, x, y, args)
    return Common.sprite_child(Common.child_id(id, "dot_" .. i), args.dot_quad_key or "dot-1", {
        x = x,
        y = y,
        w = args.dot_w or 0.055,
        r = args.dot_r or 0,
    }, {
        shadow        = args.dot_shadow,
        shadow_color  = args.dot_shadow_color or tint_alpha(Common.ck, 0.16),
        tint          = args.dot_tint or ctd,
        sprite_color  = args.dot_sprite_color or args.dot_tint or ctd,
        hover_color   = args.dot_hover_color,
        parent_hover_tint = args.dot_parent_hover_tint ~= false,
        widget_dist   = args.dot_widget_dist or 1,
    })
end

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local out    = {}
    local count  = args.dot_count or 5
    local x,  y  = args.dot_x or _dot_x, args.dot_y or _dot_y
    local gap    = args.dot_gap or _dot_gap
    for i = 1, count do out[#out + 1] = _dot_child(id, i, x, y + (i - 1)*gap, args) end
    return out
end

return M
