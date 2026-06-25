local base              = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.base")
local child_widgets_mod = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets")

local N = false

local cfg = {}
for k, v in pairs(base) do cfg[k] = v end

--- Helper: _default
local function _default(v, fallback) if v ~= nil then return v end; return fallback end

-----------------------------
--- prototype
----------------------------------
return function(args)
    args = args or {}
    local hover_tint = args.hover_tint or cfg.hover_tint

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
        button = _default(args.button, cfg.button),     can_hover = _default(args.can_hover, cfg.can_hover),
        can_click = _default(args.can_click, cfg.can_click), can_drag = N,
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
