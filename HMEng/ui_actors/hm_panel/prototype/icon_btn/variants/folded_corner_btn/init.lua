local _btn_dir  = "HMEng.ui_actors.hm_panel.prototype.icon_btn."

local IconBtn   = require(_btn_dir .. ".default")
local Common    = require(_btn_dir .. ".variants.folded_corner_btn.common")
local Layout    = require(_btn_dir .. ".variants.folded_corner_btn.layout")
local Children  = require(_btn_dir .. ".variants.folded_corner_btn.children")
local Relayout  = require(_btn_dir .. ".variants.folded_corner_btn.relayout")

local N = false

local Type3, Type4 = Common.type3_cfg, Common.type4_cfg

local M = {}

-----------------------------
--- main: layout
-----------------------------
function M.layout(args) return Layout.compute(Common.with_defaults(args)) end

-----------------------------
--- main: button config
-----------------------------
function M.build(args)
    args = Common.with_defaults(args)
    local id = args.id or "folded_corner_btn"
    local layout = Layout.compute(args)
    local shadow_layer, face_layer = args.shadow_layer or args._folded_cfg.base.shadow_layer, args.face_layer or args._folded_cfg.base.face_layer
    local btn = {
        --- basics
        id = id,                                    T = Layout.button_T(args, layout),

        --- hit test
        button    = args.button ~= N,               can_hover      = args.can_hover ~= N,
        can_drag  = N,                              can_click      = args.can_click ~= N,
        hit_shape = "rect",                         hit_padding    = Layout.scale_T(args.hit_padding or { x = 0.04, y = 0.08 }, layout.group_scale),
        hook_fn   = args.hook_fn,                   hover_hook_fn  = args.hover_hook_fn,

        --- hover settings
        hover_tint   = args.hover_tint or 0,        click_visual_time = args.click_visual_time or 0.12,
        widget_dist  = args.widget_dist or 0.75,

        --- child widgets
        child_widgets = Children.build(id, args, layout, shadow_layer, face_layer),
    }

    btn.style = IconBtn(btn)
    return btn
end

-----------------------------
--- public helpers
-----------------------------
M.relayout         = Relayout.apply
M.anchor_T         = Common.anchor_T
M.anchor_offset_T  = Common.anchor_offset_T

M.anchor_offset    = { x = Type3.layout.anchor_cx*Type3.layout.group_scale, y = Type3.layout.anchor_cy*Type3.layout.group_scale }
M.label_suffix     = Type3.base.label_suffix
M.defaults         = Type3.defaults
M.type3_cfg        = Type3
M.type4_cfg        = Type4

function M.label_id(id) return (id or "folded_corner_btn") .. Type3.base.label_suffix end

return M
