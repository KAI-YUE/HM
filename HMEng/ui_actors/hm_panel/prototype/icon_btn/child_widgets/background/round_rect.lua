local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local tint_alpha = Common.tint_alpha
local ck, ctd    = Common.ck, Common.ctd

local N = false

local M = {}

--- Helper: round_rect_common
local function _round_rect_common(id, args)
    local fill_color = args.bg_fill_color or args.bg_sprite_color or ctd
    local hover_tint = args.hover_tint or 0
    return {
        --- basics
        style  = "round_rect",                  id = Common.child_id(id, "bg"),
        T      = Common.bg_T(args),

        --- hit settings
        button     = N,                         can_hover  = N,
        can_click  = N,                         can_drag   = N,

        --- color settings
        fill_color   = fill_color,              idle_color         = { fill_color = fill_color },
        shadow       = args.bg_shadow,          hover_tint         = args.bg_hover_tint or hover_tint,
        widget_dist  = args.widget_dist or 0.8, parent_hover_tint  = args.bg_parent_hover_tint ~= N,
        shadow_color = args.bg_shadow_color or tint_alpha(ck, 0.30),
    }
end

--- Helper: build
function M.build(id, args)
    local child = _round_rect_common(id, args)
    child.round_radius = args.bg_round_radius or args.bg_radius or 0.04
    return child
end

return M
