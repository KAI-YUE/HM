local IconBtn  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Tree     = require("HMEng.ui_actors.common.tree")
local Cfg      = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.tab_color_var_btn.tab_color_var_btn_type1_cfg")

local Y, N = true, false

local M = {}

--------------------------------------------------
--- colors
--------------------------------------------------
--- Helper: state_colors
local function state_colors(args, active)
    if active then
        local colors = Cfg.color.active
        return args.active_mask_color or colors.mask, args.active_label_color or colors.label
    end

    local colors = Cfg.color.idle
    return args.mask_color or colors.mask, args.label_color or colors.label
end

--------------------------------------------------
--- build
--------------------------------------------------
function M.build(args)
    args = args or {}
    local B,          K            = Cfg.base,                        Cfg.mask
    local T,          L            = args.T or { w = B.w, h = B.h },  Cfg.label
    local LT,         active       = args.label_T or L.T,             args.active == Y
    local mask_color, label_color  = state_colors(args, active)

    local btn = {
        --- basics
        id         = args.id or B.id,                                       T          = T,
        show_icon  = N,                                                     show_dots  = N,

        --- hit settings
        button       = not active,                                          can_hover  = not active,
        can_click    = not active,                                          hook_fn    = args.hook_fn,
        hover_hook_fn = args.hover_hook_fn,
        hover_arrow  = N,

        --- background settings
        bg_style      = args.bg_style or K.style,                           bg_atlas_key     = args.bg_atlas_key or K.atlas_key,
        bg_quad_key   = args.bg_quad_key or K.quad_key,                     bg_w             = args.bg_w or T.w or B.w,
        bg_h          = args.bg_h or T.h or B.h,                            bg_sprite_color  = mask_color,
        bg_shadow     = K.shadow or args.bg_shadow,

        --- label settings
        label                    = args.label,                              label_x           = LT.x,
        label_y                  = LT.y,                                    label_w           = LT.w or ((T.w or B.w) - (LT.w_trim or 0)),
        label_h                  = LT.h,                                    label_text_scale  = args.label_text_scale or L.scale,
        label_lang               = args.label_lang,                         label_font_type   = args.label_font_type,
        label_text_line_spacing  = args.label_text_line_spacing,            label_i18n_type   = args.label_i18n_type,
        label_i18n_scope         = args.label_i18n_scope,                   label_i18n_key    = args.label_i18n_key,
        label_i18n_fallback      = args.label_i18n_fallback,                label_align       = args.label_align,
        label_text_offset        = args.label_text_offset,
        label_parent_hover_tint  = args.label_parent_hover_tint,
        label_color              = label_color,                             label_idle_color = label_color,
        label_hover_color        = args.label_hover_color or L.hover_color,
        
    }

    btn.style = IconBtn(btn)
    return btn
end

--------------------------------------------------
--- active state
--------------------------------------------------
function M.set_active(widget, active, args)
    if not widget then return end
    args = args or {}
    local mask_color, label_color = state_colors(args, active)
    
    widget.disable_button = active
    widget.config.button,    widget.config.can_hover, widget.config.can_click    = not active, not active, not active
    widget.states.hover.can, widget.states.click.can, widget.states.collide.can  = not active, not active, not active
    
    if active then widget.states.hover.is = N end

    local id           = widget.config.id or args.id or Cfg.base.id
    local mask, label  = Tree.find_child_by_id(widget, id .. "_bg"),       Tree.find_child_by_id(widget, id .. "_label")
    
    if mask  then mask.config.sprite_color, mask.config.tint = mask_color, mask_color end
    if label then label.config.text_color, label.config.idle_text_color = label_color, label_color end
end

M.type1_cfg = Cfg

return M
