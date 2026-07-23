local C      = require("HMfns.animate.color.color_const")
local Boxes  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row.boxes")
local Paint  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row.paint")

local ccrm, ck = C.CREAM, C.BLACK

local Y, N = true, false

local M = {}

--- default params
local _default_row_h,    _hype_box_h_scale   = 0.21, 4
local _edge_outer_inset, _edge_outer_offset  = { x = 0.02, y = 0.01 }, { x = 1,  y = 0.08 }
local _edge_inner_inset, _edge_inner_offset  = { x = 0.04, y = 0.02 }, { x = 2,  y = 0.16 }

-----------------------------
--- public factory: make
----------------------------------
function M.make(args)
    args = args or {}
    local id, row_h   = args.id or "option_row", args.h or (args.T and args.T.h) or _default_row_h
    args.id,  args.h  = id, row_h

    local row_T       = Paint.row_T(args, row_h)
    local paint, paint_seed_entry = Paint.resolve_paint(args)
    local hover_edge  = (args.hover_edge ~= N)

    return { --- basic settings
        style    = "paint_rect",                                    T = row_T,
        renderer = "option_row_paint_rect",                         paint_rect_renderer = Y,
        id       = id,

        --- hit settings
        hit_scale  = { x = 2.5, y = 7 },                            hit_offset  = { x = 2.45, y = 0.6 },
        button     = N,                                             can_hover   = hover_edge and (args.can_hover ~= N) or args.can_hover,
        can_click  = N,                                             can_collide = args.can_collide,
        can_drag   = N,
        focus_args = args.focus_args,

        --- additional hover settings
        hover_edge              = hover_edge,                       hover_edge_color        = ccrm,
        hover_edge_outer_inset  = _edge_outer_inset,                hover_edge_outer_offset = _edge_outer_offset,
        hover_edge_inner_inset  = _edge_inner_inset,                hover_edge_inner_offset = _edge_inner_offset,
        hover_edge_wobble       = paint.wobble,                     hover_edge_bleed        = paint.bleed,
        hover_edge_grace_s      = args.hover_edge_grace_s or 0.06,  hover_edge_fade_s       = args.hover_edge_fade_s or 0.12,

        --- i18n settings
        i18n_type = args.i18n_type,                                 i18n_scope = args.i18n_scope,

        --- color settings
        fill_color = args.fill_color or ck,                         idle_color = Paint.idle_color(args.fill_color or ck),
        hover_tint = args.hover_tint or 0,
        shadow     = (args.shadow ~= N),                            shadow_color = args.shadow_color or { 0, 0, 0, 0.18 },

        --- misc
        paint = paint,                                              paint_seed_entry = paint_seed_entry,
        page_switch_wipe = (args.page_switch_wipe ~= N),

        --- child widgets
        child_widgets = {
            Boxes.text_box(args, _hype_box_h_scale*row_h),
            Boxes.control_widget_box(args, _hype_box_h_scale*row_h),
        },
    }
end

return M
