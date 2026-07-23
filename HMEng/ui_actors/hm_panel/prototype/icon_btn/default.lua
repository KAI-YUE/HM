local base              = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.base")
local child_widgets_mod = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets")

local N = false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

-----------------------------
--- prototype
----------------------------------
return function(args)
    args = args or {}
    local hover_tint = args.hover_tint or cfg.hover_tint
    local button, can_hover, can_click = args.button, args.can_hover, args.can_click
    if button == nil    then button = cfg.button end
    if can_hover == nil then can_hover = cfg.can_hover end
    if can_click == nil then can_click = cfg.can_click end

    ----------------------------------------
    --- child widget defaults
    ----------------------------------------
    local child_args = {}
    for k, v in pairs(args) do child_args[k] = v end
    child_args.hover_tint = hover_tint

    return {
        --- basics
        type = cfg.type,                                renderer = cfg.renderer,

        --- hit settings
        button = button,                                can_hover = can_hover,
        can_click = can_click,                          can_drag = N,
        hit_shape = cfg.hit_shape,                      hit_padding = args.hit_padding or cfg.hit_padding,
        hook_fn = args.hook_fn,                         hover_hook_fn = args.hover_hook_fn,

        --- container settings
        shadow = cfg.shadow,                            text_overlay = cfg.text_overlay,
        hover_tint = hover_tint,                          click_visual_time = args.click_visual_time or cfg.click_visual_time,
        widget_dist = args.widget_dist or cfg.widget_dist,

        --- child widgets
        child_widgets = args.child_widgets or child_widgets_mod.build(child_args),
    }
end
