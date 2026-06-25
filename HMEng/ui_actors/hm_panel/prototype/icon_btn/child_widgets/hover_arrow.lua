local C      = require("HMfns.animate.color.color_const")
local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local tint_alpha = Common.tint_alpha

local ctd   = Common.ctd
local ccrm  = C.CREAM
local cpaper = C.TITLE.PAPER

local Y, N = true, false

local M = {}

local _ax, _ay = -1, 0.1
local _aw = 0.6

--- Helper: arrow_T | _arg_or
local function _arrow_T(args) return { x = _ax, y = _ay, w = _aw, } end
local function _arg_or(args, key, fallback) if args[key] ~= nil then return args[key] end; return fallback end

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local child = Common.sprite_child(Common.child_id(id, "hover_arrow"), args.hover_arrow_quad_key or "arrow-9", _arrow_T(args), {
        shadow        = args.hover_arrow_shadow,
        shadow_color  = args.hover_arrow_shadow_color or tint_alpha(Common.ck, 0.22),
        tint          = args.hover_arrow_tint or ctd,
        sprite_color  = args.hover_arrow_sprite_color or ctd,
        fill_color    = args.hover_arrow_fill_color or cpaper,
        widget_dist   = args.hover_arrow_widget_dist or 1.05,
    })

    child.sprite_mask_key           = args.hover_arrow_mask_key or "arrow_mask"
    child.sprite_mask_offset        = args.hover_arrow_mask_offset or { x = 0, y = -0.05 }
    child.sprite_mask_scale         = args.hover_arrow_mask_scale or 1.3
    child.sprite_mask_deco_color    = _arg_or(args, "hover_arrow_mask_deco_color", tint_alpha(ctd, 0.75))
    child.sprite_mask_deco_offset   = args.hover_arrow_mask_deco_offset or { x = 0, y = -0.05 }
    child.sprite_mask_deco_scale    = args.hover_arrow_mask_deco_scale or 1.4
    child.show_on_parent_hover      = (args.hover_arrow_show_on_parent_hover ~= N)
    child.parent_hover_reveal_s     = args.hover_arrow_reveal_s or 0.16
    child.parent_hover_reveal_ease  = args.hover_arrow_reveal_ease or "sine"
    child.button                    = N
    child.can_hover                 = (args.hover_arrow_can_hover == Y)
    child.can_click                 = N
    child.can_drag                  = N
    return child
end

return M
