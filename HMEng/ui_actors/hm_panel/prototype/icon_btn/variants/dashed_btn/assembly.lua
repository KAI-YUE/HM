local IconBtn    = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local PaintSeeds = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.paint_seeds")
local PaintRect  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background.btn_bg_paint_rect")
local TabUtils   = require("HMfns.utils.table_utils")
local Cfg        = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.dashed_btn.dashed_btn_type1_cfg")

local rand_pick  = TabUtils.random_pick

local N = false

local M = {}

--- Helper: paint_seed | paint
local function paint_seed(args) return (args and args.paint_seed_entry) or rand_pick(PaintSeeds) end
local function paint(seed_entry, args)
    seed_entry,  args  = seed_entry or {}, args or {}
    local widget_dist  = args.widget_dist or 1
    return PaintRect.paint_from_seed(seed_entry, args.bg_paint, {
        shader      = Cfg.paint.shader,             wobble      = Cfg.paint.wobble,
        bleed       = Cfg.paint.bleed,              feather_px  = Cfg.paint.feather_px,
        widget_dist = widget_dist,
    })
end

-----------------------------
--- main: button config
----------------------------
function M.build(args)
    args = args or {}
    local active            = args.active ~= N
    local paint_seed_entry  = paint_seed(args)
    local label_color       = active and (args.label_color or Cfg.label.color) or (args.disabled_label_color or Cfg.label.disabled_color)
    local T                 = args.T or { x = args.x or 0, y = args.y or 0, w = args.w or Cfg.base.w, h = args.h or Cfg.base.h }
    local btn = {
        --- basics
        id        = args.id or "dashed_btn",                  T = T,
        room_ref  = args.room_ref ~= N,

        --- label & icon
        label = args.label,                                   label_lang = args.label_lang,
        icon_quad_key = args.icon_quad_key or Cfg.icon.quad_key,

        --- hit settings
        hit_scale   = args.hit_scale or Cfg.hit.scale,        hit_offset  = args.hit_offset or Cfg.hit.offset,
        button      = active,                                 can_hover   = active,
        can_click   = active,                                 hook_fn     = args.hook_fn,
        widget_dist = args.widget_dist or Cfg.widget_dist,

        --- sprite settings
        bg_w    = args.bg_w or Cfg.base.w,                    icon_x = args.icon_x or Cfg.icon.x,
        icon_y  = args.icon_y or Cfg.icon.y,                  icon_w = args.icon_w or Cfg.icon.w,

        --- label settings
        label_x           = args.label_x or Cfg.label.x,      label_y = args.label_y or Cfg.label.y,
        label_w           = args.label_w or Cfg.label.w,      label_h = args.label_h or Cfg.label.h,
        label_text_scale  = args.label_text_scale or Cfg.label.text_scale, label_color = label_color,
        label_hover_color = args.label_hover_color or Cfg.label.hover_color,

        --- color settings
        icon_tint        = args.icon_tint or Cfg.icon.tint,   dot_tint = args.dot_tint or Cfg.icon.tint,
        icon_hover_color = args.icon_hover_color or Cfg.icon.hover_color, dot_hover_color = args.dot_hover_color or Cfg.icon.hover_color,

        --- background style 
        bg_style         = Cfg.bg.style,                      bg_sprite_color = args.bg_sprite_color or Cfg.bg.color,
        bg_shadow        = args.bg_shadow ~= N,               bg_shadow_color = args.bg_shadow_color or Cfg.bg.shadow_color,
        bg_paint         = paint(paint_seed_entry, args),
    }

    btn.style = IconBtn(btn)
    return btn
end

M.type1_cfg = Cfg

return M
