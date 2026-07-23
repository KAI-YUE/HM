local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")
local C = require("HMfns.animate.color.color_const")

local tint_alpha = Common.tint_alpha
local ctd = Common.ctd

local M = {}

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local tint = args.icon_tint or ctd
    return Common.sprite_child(Common.child_id(id, "icon"), args.icon_quad_key or "log", {
        x = args.icon_x or 0.16,
        y = args.icon_y or 0.14,
        w = args.icon_w or 0.46,
        r = args.icon_r or 0,
    }, {
        atlas_key     = args.icon_atlas_key,
        shadow        = args.icon_shadow,
        shadow_color  = args.icon_shadow_color or tint_alpha(Common.ck, 0.24),
        tint          = tint,
        sprite_color  = args.icon_sprite_color or tint,
        hover_color  = (args.icon_hover_color ~= nil) and args.icon_hover_color or C.ORANGE,
        hover_tint    = args.icon_hover_tint or args.hover_tint or 0,
        parent_hover_tint = args.icon_parent_hover_tint ~= false,
        widget_dist   = args.icon_widget_dist or 1.1,
    })
end

return M
