local IconBtn  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Common   = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.common")
local Layout   = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.layout")
local Children = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.children")
local Hooks    = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.hooks")

local Cfg = Common.cfg()

local _hint_T = Common.hint_T
local _glyph_keys, _mask_quad_cfg, _mask_quad_key = Layout.glyph_keys, Layout.mask_quad_cfg, Layout.mask_quad_key

local Y, N = true, false
local function _default(value, fallback) if value ~= nil then return value end; return fallback end

local M = {}

-----------------------------
--- child list
-----------------------------
local function _children(id, args)
    local children = {}
    local root_parent_press_squash = args.parent_press_squash
    args.parent_press_squash = Y
    local debug_bg = Children.debug_bg_child(id .. "_debug_bg", args);          if debug_bg then children[#children + 1] = debug_bg end

    local base_mask_key = args.hint_btn_quad_key or _glyph_keys(args)[1]
    local mask_key      = args.hint_mask_key or base_mask_key
    local mask_cfg  = _mask_quad_cfg(args, mask_key)
    local mask_quad = _mask_quad_key(args, mask_cfg, mask_key)
    local btn_child = Children.btn_child(id, args);                             if btn_child then children[#children + 1] = btn_child end
    local mask_child = Children.mask_child(id, args, mask_cfg, mask_quad);      if mask_child then children[#children + 1] = mask_child end
    if args.hint_icon ~= N then for _, child in ipairs(Children.glyph_child_widgets(id, args)) do children[#children + 1] = child end end
    local textfx_label = Children.textfx_label_child(id .. Cfg.base.label_suffix, args)
    children[#children + 1] = textfx_label or Children.text_child(id .. Cfg.base.label_suffix, args)
    args.parent_press_squash = root_parent_press_squash == nil and Y or root_parent_press_squash
    return children, mask_cfg, mask_quad
end

-----------------------------
--- main
-----------------------------
function M.build(args)
    args = args or {}
    if args.btn_shadow_same_layer == nil and args.btn_shadow_under_mask ~= nil then args.btn_shadow_same_layer = not args.btn_shadow_under_mask end
    if args.shadow_parallax == nil then args.shadow_parallax = Cfg.shadow.parallax end
    args.hid_action = args.hid_action or Cfg.hid.hid_action
    if args.hint_enter_wipe or args.parent_cut_in_sync then args.text_mask_shader, args.text_mask_ref, args.text_mask_dir_ref = args.text_mask_shader or args.parent_cut_in_shader or args.hint_enter_wipe_shader or "_-2_stroke_wipe", args.text_mask_ref or "fx_mask", args.text_mask_dir_ref or "fx_mask_dir" end
    local id = args.id or Cfg.base.id
    local children, mask_cfg, mask_quad = _children(id, args)
    local hover_tint = Cfg.hint.hover_tint or 0

    local btn = {
        --- basics
        id    = id,                                                                 T         = _hint_T(args),
        type  = Cfg.base.type,                                                      renderer  = Cfg.base.renderer,
        page_draw_layer = _default(args.page_draw_layer, Cfg.hint.page_draw_layer),

        --- hint input
        hid_action        = args.hid_action,                                         hid_button       = args.hid_button,
        options_tab_step  = args.options_tab_step,

        --- hint glyph
        hint_atlas_key         = args.hint_atlas_key or Cfg.glyph.atlas_key,
        hint_icon_quad_key     = args.hint_icon_quad_key,                            hint_icon_quad_keys   = args.hint_icon_quad_keys,
        hint_console           = args.hint_console,                                  hint_label_map        = args.hint_label_map,
        hint_icon_show_when    = args.hint_icon_show_when,
        hint_label_i18n_key    = args.hint_label_i18n_key,                           hint_label_i18n_type  = args.hint_label_i18n_type,
        hint_label_i18n_scope  = args.hint_label_i18n_scope,
        label_x_offset_by_lang = args.label_x_offset_by_lang,

        --- hint mask
        hint_mask_atlas_key  = args.hint_mask_atlas_key or mask_cfg.atlas_key,       hint_mask_quad_key   = args.hint_mask_quad_key or mask_quad,
        hint_mask_suffix     = mask_cfg.suffix,                                      hint_mask_map        = args.hint_mask_map or Cfg.mask_by_quad,

        --- hint display
        show_when            = args.show_when or Cfg.hint.show_when,
        show_when_parent     = args.show_when_parent,
        shadow_parallax      = args.shadow_parallax,                                 widget_dist          = args.widget_dist,
        click_visual_time    = args.click_visual_time,                               hint_enter_fade      = args.hint_enter_fade,
        opt_tab_cut_in_sync  = args.opt_tab_cut_in_sync,                             hint_enter_wipe      = args.hint_enter_wipe,
        parent_cut_in_sync   = args.parent_cut_in_sync,
        parent_cut_in_delay  = args.parent_cut_in_delay,                                  parent_cut_in_time = args.parent_cut_in_time,
        parent_cut_in_ease   = args.parent_cut_in_ease,
        page_switch_enter_start = args.page_switch_enter_start,                      page_switch_enter_time = args.page_switch_enter_time,

        --- hit settings
        button       = args.button ~= N,                                             can_hover   = args.can_hover ~= N,
        can_click    = args.can_click ~= N,                                          can_drag    = N,
        can_collide  = args.can_collide ~= N,                                        shadow      = N,
        gamepad_focus = args.gamepad_focus,
        slot_idx     = args.slot_idx,
        hit_mask_box = args.hit_mask_box ~= N,
        parent_press_squash = args.parent_press_squash,
        hook_fn      = Hooks.hint_hook(args),                                        hover_tint  = args.hover_tint or hover_tint,

        --- child widgets
        child_widgets = children,
    }

    btn.style = IconBtn(btn)
    btn.style.type, btn.style.renderer = Cfg.base.type, Cfg.base.renderer
    return btn
end

return M
