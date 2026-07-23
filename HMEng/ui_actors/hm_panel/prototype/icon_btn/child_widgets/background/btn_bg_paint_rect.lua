local C      = require("HMfns.animate.color.color_const")
local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.common")

local tint_alpha  = Common.tint_alpha
local ck, ctd     = Common.ck, Common.ctd

local Y, N = true, false

local M = {}

-----------------------------
--- paint seed resolution
-----------------------------
function M.paint_from_seed(seed_entry, paint, defaults)
    local out = {}
    for k, v in pairs(defaults or {})   do out[k] = v end
    for k, v in pairs(seed_entry or {}) do out[k] = v end
    for k, v in pairs(paint or {})      do out[k] = v end
    out.paint_seed_entry = seed_entry
    return out
end

-----------------------------
--- Role: icon-button background config builder
--- Builds child cfg for the love_brew paint_rect renderer.
-----------------------------
-----------------------------
--- paint cfg helpers
----------------------------------
--- Helper: paint arg
local function _paint_arg(args, key)     return args["bg_" .. key] or args["bg_paint_" .. key] end

--- Helper: paint seed
local function _paint_seed(args, paint)  paint = paint or args.bg_paint or {}; return paint.paint_seed or paint.seed end

--- Helper: paint seed entry
local function _paint_seed_entry(args, paint)
    if args.paint_seed_entry            then return args.paint_seed_entry end
    if paint and paint.paint_seed_entry then return paint.paint_seed_entry end

    local seed = _paint_seed(args, paint)
    return { seed = seed,                        x_mul  = args.paint_x_mul or 0.05,
        y_mul     = args.paint_y_mul or 0.7,     w_mul  = args.paint_w_mul or 2.5,
        h_mul     = args.paint_h_mul or 6.5,     x      = args.paint_x,
        y         = args.paint_y,                w      = args.paint_w,
        h         = args.paint_h,                wobble = args.paint_wobble,
        bleed     = args.paint_bleed,            feather_px = args.paint_feather_px,
    }
end

--- Helper: build paint cfg
local function _build_paint(args)
    local paint = {
        shader = _paint_arg(args, "shader"),       color = args.bg_fill_color or args.bg_sprite_color,
    }

    paint.seed        = _paint_arg(args, "seed") or _paint_seed(args, paint)
    paint.wobble      = _paint_arg(args, "wobble")
    paint.bleed       = _paint_arg(args, "bleed")
    paint.wave_px     = _paint_arg(args, "wave_px")
    paint.feather_px  = _paint_arg(args, "feather_px")
    paint.fx_mask_ref = _paint_arg(args, "fx_mask_ref")
    paint.fx_mask_dir_ref = _paint_arg(args, "fx_mask_dir_ref")
    paint.widget_dist = _paint_arg(args, "widget_dist")

    paint.x_mul = _paint_arg(args, "x_mul")
    paint.y_mul = _paint_arg(args, "y_mul")
    paint.w_mul = _paint_arg(args, "w_mul")
    paint.h_mul = _paint_arg(args, "h_mul")
    paint.x     = _paint_arg(args, "x")
    paint.y     = _paint_arg(args, "y")
    paint.w     = _paint_arg(args, "w")
    paint.h     = _paint_arg(args, "h")
    local explicit   = args.bg_paint or paint
    local seed_entry = _paint_seed_entry(args, explicit)
    return M.paint_from_seed(seed_entry, explicit, { shader = "_1_watercolor_edge", color = ctd, feather_px = 0.08 })
end

-----------------------------
--- hover edge cfg helpers
----------------------------------
--- Helper: hover edge defaults
local function _hover_edge_enabled(args) return args.bg_hover_edge == Y end

--- Helper: hover edge paint defaults
local function _hover_edge_paint_defaults(args, paint)
    if not _hover_edge_enabled(args) then return paint end

    paint.shader          = _paint_arg(args, "shader") or paint.shader or "_-4_watercolor_slot_wipe"
    paint.wobble          = _paint_arg(args, "wobble") or paint.wobble or 1.2
    paint.bleed           = _paint_arg(args, "bleed") or paint.bleed or 1.6
    paint.feather_px      = _paint_arg(args, "feather_px") or paint.feather_px or 1
    paint.widget_dist     = _paint_arg(args, "widget_dist") or paint.widget_dist or 1.4
    paint.fx_mask_ref     = _paint_arg(args, "fx_mask_ref") or paint.fx_mask_ref or "fx_mask"
    paint.fx_mask_dir_ref = _paint_arg(args, "fx_mask_dir_ref") or paint.fx_mask_dir_ref or "fx_mask_dir"
    return paint
end

-----------------------------
--- child cfg helpers
----------------------------------
--- Helper: paint rect child cfg
local function _paint_rect_child_cfg(id, args)
    local fill_color = args.bg_fill_color or args.bg_sprite_color or ctd
    local hover_edge = _hover_edge_enabled(args)
    local hover_tint = args.hover_tint or 0

    return {
        --- basics
        style = "paint_rect",             id = Common.child_id(id, "bg"),
        renderer = hover_edge and "option_row_paint_rect" or args.bg_renderer,
        paint_rect_renderer = Y,
        T = Common.bg_T(args),

        --- hit settings
        button = N,                       can_hover = hover_edge and (args.bg_can_hover ~= N) or N,
        can_click = N,                    can_drag = N,

        --- hover edge settings
        hover_edge              = hover_edge,                                       hover_edge_color        = args.bg_hover_edge_color or C.CREAM,
        hover_edge_outer_inset  = args.bg_hover_edge_outer_inset or { x = 0.02, y = 0.01 }, hover_edge_outer_offset = args.bg_hover_edge_outer_offset or { x = 0.18, y = 0.02 },
        hover_edge_inner_inset  = args.bg_hover_edge_inner_inset or { x = 0.05, y = 0.03 }, hover_edge_inner_offset = args.bg_hover_edge_inner_offset or { x = 0.34, y = 0.04 },
        hover_edge_grace_s      = args.bg_hover_edge_grace_s or 0.06,
        hover_edge_fade_s       = args.bg_hover_edge_fade_s or 0.12,

        --- color settings
        fill_color = fill_color,          idle_color = { fill_color = fill_color },
        hover_tint = args.bg_hover_tint or hover_tint, parent_hover_tint = args.bg_parent_hover_tint ~= N,
        shadow = args.bg_shadow,          shadow_color = args.bg_shadow_color or tint_alpha(ck, 0.30),
        widget_dist = args.widget_dist or 0.8,
    }
end

---____________________________
--- main: build
---______________________________________
function M.build(id, args)
    local child = _paint_rect_child_cfg(id, args)
    child.paint                   = _hover_edge_paint_defaults(args, _build_paint(args))
    child.paint.seed              = child.paint.seed or _paint_seed(args, child.paint)
    child.paint.paint_seed_entry  = child.paint.paint_seed_entry or _paint_seed_entry(args, child.paint)
    child.paint_seed_entry        = child.paint.paint_seed_entry
    child.paint_alpha             = args.paint_alpha
    child.hover_edge_bleed        = args.bg_hover_edge_bleed or child.paint.bleed
    child.hover_edge_wobble       = args.bg_hover_edge_wobble or child.paint.wobble
    return child
end

return M
