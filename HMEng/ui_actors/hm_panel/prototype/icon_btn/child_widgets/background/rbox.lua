local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local tint_alpha = Common.tint_alpha
local ctd = Common.ctd

local Y, N = true, false

local M = {}

--- Helper: _sprite_smooth_paint
local function _sprite_smooth_paint(args)
    if args.bg_paint == N then return N end
    return args.bg_paint or {
        shader                   = "_0_sprite_edge_smooth",
        sprite_smooth_radius     = args.bg_smooth_radius or 3,
        sprite_smooth_strength   = args.bg_smooth_strength or 4,
        sprite_smooth_threshold  = args.bg_smooth_threshold or 1,
    }
end

--- Helper: build
function M.build(id, args)
    local child = Common.sprite_child(Common.child_id(id, "bg"), args.bg_quad_key or "rbox-1", {
        x = args.bg_x or 0,
        y = args.bg_y or 0,
        w = args.bg_w or 1.85,
        r = args.bg_r or 0,
    }, {
        shadow = args.bg_shadow,
        shadow_color = args.bg_shadow_color or tint_alpha(Common.ck, 0.30),
        sprite_color = args.bg_sprite_color or ctd,
        hover_tint = args.bg_hover_tint or args.hover_tint or 0,
        parent_hover_tint = args.bg_parent_hover_tint ~= N,
        widget_dist = args.widget_dist or 0.8,
    })

    child.paint = _sprite_smooth_paint(args)
    return child
end

return M
