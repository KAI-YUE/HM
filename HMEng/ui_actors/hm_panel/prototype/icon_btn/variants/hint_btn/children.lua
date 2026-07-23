local HintLabel  = require("HMEng.ui_actors.card_textfx.presets.hint_label")
local Common     = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.common")
local Layout     = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.layout")

local Cfg     = Common.cfg()
local _hint_r,      _with      = Common.hint_r,      Common.with
local _base_T,      _btn_T     = Layout.base_T,      Layout.btn_T
local _glyph_keys,  _glyph_T   = Layout.glyph_keys,  Layout.glyph_T
local _label_T,     _mask_T    = Layout.label_T,     Layout.mask_T

local Y, N = true, false

local M = {}

--- Helpers: config helpers |  _default | _shadow_layer | _text_color
local function _cfg(base, override)                                       local out = _with({}, base); return _with(out, override) end
local function _default(value, fallback)                                  if value == nil then return fallback end; return value end
local function _shadow_layer(args, same_key, layer_key, cfg, face_layer)  if args[same_key] == Y then return face_layer end; return args[layer_key] or (cfg and cfg.shadow_layer) or 0 end
local function _text_color(args)                                          if args.text_color then return args.text_color end; return args.label_on_btn and Cfg.glyph.tint or Cfg.label.color end

------------------------------------------
--- debug_bg_child
------------------------------------------
function M.debug_bg_child(id, args)
    if args.debug_bg ~= Y then return end
    return {
        --- basics
        style  = "round_rect",                                        T = args.debug_bg_T or { x = Cfg.debug_bg.x, y = Cfg.debug_bg.y, w = args.debug_bg_w or ((args.T and args.T.w) or Cfg.debug_bg.w), h = args.debug_bg_h or ((args.T and args.T.h) or Cfg.debug_bg.h), r = _hint_r(args) },
        id     = id,                                                  draw_order = args.debug_draw_order or 0,

        --- hit settings
        button     = N,                                               can_hover  = N,
        can_click  = N,                                               can_drag   = N,

        --- debug color
        fill_color    = args.debug_bg_color  or Cfg.debug_bg.color,   shadow = N,
        round_radius  = args.debug_bg_radius or Cfg.debug_bg.radius,
    }
end

------------------------------------------
--- sprite_child
------------------------------------------
function M.sprite_child(id, atlas_key, quad_key, T, args)
    args = args or {}
    local tint = args.tint or Cfg.glyph.tint
    return {
        --- basics
        style         = "sprite_in_page",                               id          = id,
        atlas_key     = atlas_key,                                      quad_key    = quad_key,
        T             = T,                                              draw_order  = args.draw_order,
        fit_axis      = args.fit_axis,
        quad_T        = args.quad_T,                                    quad_T_map  = args.quad_T_map,
        quad_T_index  = args.quad_T_index,                              quad_T_gap  = args.quad_T_gap,
        role          = args.role,
        shadow_layer  = args.shadow_layer,                              face_layer  = args.face_layer,

        --- hit settings
        button     = N,                                                 can_hover  = N,
        can_click  = N,                                                 can_drag   = N,

        --- color settings
        tint                 = tint,                                    sprite_color  = args.sprite_color or tint,
        shadow               = args.shadow,                             shadow_color  = args.shadow_color,
        shadow_parallax      = args.shadow_parallax,
        widget_dist          = args.widget_dist,
        parent_press_squash  = args.parent_press_squash,
        paint                = args.paint,
        slot_enter_shader    = args.slot_enter_shader,
    }
end

------------------------------------------
--- textfx_label_child
------------------------------------------
function M.textfx_label_child(id, args)
    if args.label_textfx ~= Y then return end
    local T = _label_T(args)
    local draw_order = (args.hint_btn_quad_key and 4) or 3
    local textfx = HintLabel.textfx(args.label or Cfg.label.text, { x = 0, y = 0, w = T.w, h = T.h }, {
        sampling_seed = args.label_textfx_sampling_seed,           text_scale = args.text_scale or Cfg.label.text_scale,
        text_align = args.text_align or Cfg.label.align,            card_text_color = _text_color(args),
        text_bg_color = args.label_textfx_bg_color,                 text_bg_widget_dist = args.label_textfx_widget_dist,
        paint_seed_index = args.label_textfx_paint_seed_index,      text_bg = args.label_textfx_bg,
        text_bg_shadow = args.label_textfx_bg_shadow,               shadow = args.label_textfx_shadow,
        fx_mask_ref = args.parent_cut_in_sync and "fx_mask",       fx_mask_shader = args.parent_cut_in_shader or "_-2_stroke_wipe",
    })

    return {
        --- basics
        style     = "paint_rect",                                  id          = id,
        T         = T,                                             draw_order  = args.label_draw_order or draw_order,
        paint_bg  = N,

        --- hit settings
        button     = N,                                             can_hover  = N,
        can_click  = N,                                             can_drag   = N,

        --- label textfx
        textfx = textfx,

        --- draw settings
        widget_dist = args.label_textfx_widget_dist,                 parent_press_squash = args.parent_press_squash,
    }
end

------------------------------------------
--- text_child
------------------------------------------
function M.text_child(id, args)
    args = args or {}
    local draw_order = (args.hint_btn_quad_key and 4) or 3
    local text_shadow, text_static = _default(args.text_shadow, Y), _default(args.text_static, Y)

    return {
        --- basics
        style  = "text_widget",                                              T           = _label_T(args),
        id     = id,                                                         draw_order  = args.label_draw_order or draw_order,

        --- hit settings
        button     = N,                                                      can_hover   = N,
        can_click  = N,                                                      can_drag    = N,

        --- text settings
        text                 = args.label        or Cfg.label.text,          text_color         = _text_color(args),
        idle_text_color      = args.idle_text_color,
        text_scale           = args.text_scale   or Cfg.label.text_scale,    text_align         = args.text_align        or Cfg.label.align,
        font_type            = args.font_type    or Cfg.label.font_type,     text_line_spacing  = args.text_line_spacing or Cfg.label.line_spacing,
        text_maxw            = args.label_max_w  or args.text_maxw,          text_wrap          = args.label_text_wrap,
        text_shadow          = text_shadow,                                  text_static        = text_static,
        shadow               = (args.text_shadow ~= N) and args.shadow,      shadow_parallax    = args.shadow_parallax,
        widget_dist          = args.widget_dist,
        text_mask_shader     = args.text_mask_shader,                        text_mask_ref      = args.text_mask_ref,
        text_mask_dir_ref    = args.text_mask_dir_ref,                       text_mask_dir      = args.text_mask_dir,
        parent_press_squash  = args.parent_press_squash,
    }
end

------------------------------------------
--- btn_child
------------------------------------------
function M.btn_child(id, args)
    if not args.hint_btn_quad_key then return end
    
    local btn_cfg           = _cfg(Cfg.btn, args.hint_btn_cfg or args.btn_cfg)
    local shadow            = _default(args.btn_shadow,      _default(btn_cfg.shadow, Cfg.shadow.btn))
    local tint, draw_order  = args.btn_tint or btn_cfg.tint, args.btn_draw_order or btn_cfg.draw_order
    local face_layer        = args.btn_face_layer or btn_cfg.face_layer
    local _s_layer          = _shadow_layer(args, "btn_shadow_same_layer", "btn_shadow_layer", btn_cfg, face_layer)

    return M.sprite_child(id .. "_btn", args.hint_btn_atlas_key or btn_cfg.atlas_key, args.hint_btn_quad_key, _btn_T(args, _base_T(args), btn_cfg), 
    {
        tint                 = tint,                                                sprite_color  = args.btn_sprite_color   or tint,
        shadow               = shadow,                                              shadow_color  = args.btn_shadow_color   or Cfg.shadow.color,
        shadow_parallax      = args.btn_shadow_parallax or args.shadow_parallax,    widget_dist   = args.btn_widget_dist    or args.widget_dist,
        parent_press_squash  = args.parent_press_squash ~= N,                       draw_order    = draw_order,
        shadow_layer         = _s_layer,                                            face_layer    = face_layer,
        paint                = args.parent_cut_in_sync and { shader = args.parent_cut_in_shader or "_-2_stroke_wipe" },
        slot_enter_shader    = args.parent_cut_in_sync and (args.parent_cut_in_shader or "_-2_stroke_wipe"),
    })
end

------------------------------------------
--- mask_child
------------------------------------------
function M.mask_child(id, args, mask_cfg, mask_quad)
    if args.hint_mask == N or not mask_quad then return end

    local shadow  = _default(args.mask_shadow, _default(mask_cfg.shadow, Cfg.shadow.mask))
    local tint    = args.mask_tint or mask_cfg.tint

    return M.sprite_child(id .. "_mask", args.hint_mask_atlas_key or mask_cfg.atlas_key, mask_quad, _mask_T(args, _base_T(args), mask_cfg), 
    {
        tint                 = tint,                                                sprite_color = args.mask_sprite_color  or tint,
        shadow               = shadow,                                              shadow_color = args.mask_shadow_color  or Cfg.shadow.color,
        shadow_parallax      = args.mask_shadow_parallax or args.shadow_parallax,   widget_dist  = args.mask_widget_dist   or args.widget_dist,
        parent_press_squash  = args.parent_press_squash ~= N,                       draw_order   = args.mask_draw_order    or mask_cfg.draw_order,
        paint                = args.parent_cut_in_sync and { shader = args.parent_cut_in_shader or "_-2_stroke_wipe" },
        slot_enter_shader    = args.parent_cut_in_sync and (args.parent_cut_in_shader or "_-2_stroke_wipe"),
    })
end

------------------------------------------
--- glyph_child_widgets
------------------------------------------
function M.glyph_child_widgets(id, args)
    local out, keys = {}, _glyph_keys(args)

    for i, key in ipairs(keys) do
        local tint         = args.icon_tint                  or  Cfg.glyph.tint
        local glyph_order  = (args.hint_btn_quad_key and 3)  or  2
        local draw_order   = args.icon_draw_order            or  glyph_order
        local face_layer   = args.icon_face_layer            or  draw_order
        local fit_axis     = args.icon_fit_axis              or  Cfg.glyph.fit_axis
        local shadow       = _default(args.icon_shadow, Cfg.shadow.glyph)
        local _s_layer     = _shadow_layer(args, "icon_shadow_same_layer", "icon_shadow_layer", nil, face_layer)

        out[#out + 1] = M.sprite_child(id .. "_icon" .. i, args.hint_atlas_key or Cfg.glyph.atlas_key, key, _glyph_T(args, i), 
        {
            tint                 = tint,                                               sprite_color = args.icon_sprite_color or tint,
            shadow               = shadow,                                             shadow_color = args.icon_shadow_color or Cfg.shadow.color,
            shadow_parallax      = args.shadow_parallax,                               widget_dist  = args.widget_dist,
            
            parent_press_squash  = args.parent_press_squash ~= N,                      draw_order   = draw_order,
            shadow_layer         = _s_layer,                                           face_layer   = face_layer,    
            paint                = args.parent_cut_in_sync and { shader = args.parent_cut_in_shader or "_-2_stroke_wipe" },
            slot_enter_shader    = args.parent_cut_in_sync and (args.parent_cut_in_shader or "_-2_stroke_wipe"),
            
            fit_axis             = fit_axis,                                           role         = (fit_axis == "width" or fit_axis == "height") and { wh_bond = "Weak" },
            quad_T               = args.glyph_T,                                       quad_T_map   = Cfg.glyph.T_by_quad,
            quad_T_index         = i,                                                  quad_T_gap   = args.glyph_gap or args.icon_gap,
        })
    end
    return out
end

return M
