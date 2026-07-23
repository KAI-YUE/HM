local C         = require("HMfns.animate.color.color_const")
local Common    = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.common")
local Layout    = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.layout")
local PaintRect = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.child_widgets.background.btn_bg_paint_rect")

local ck, co    = C.BLACK, C.ORANGE
local cw, ccrm  = C.WHITE, C.CREAM
local ctl       = C.UI.TEXT_LIGHT

local Y, N    = true, false

local M = {}
local LABEL_LAYOUT_KEYS = { "label_x", "label_y", "label_w", "label_h", "label_maxw", "label_text_scale" }

-----------------------------
--- basic children
-----------------------------
local function _sprite_child(id, atlas_key, quad_key, T, args)
    args = args or {}
    local tint = args.tint or ck
    return {
        --- basics
        style      = "sprite_in_page",              id        = id,
        atlas_key  = atlas_key,                     T         = T,
        quad_key   = quad_key,                      fit_axis  = args.fit_axis or "width",
        shadow_layer = args.shadow_layer,           face_layer = args.face_layer,

        --- hit test
        button      = N,                            can_hover = N,
        can_drag    = N,                            can_click = N,
        hover_zoom  = 1,

        --- color settings
        tint         = tint,                        sprite_color       = args.sprite_color or tint,
        hover_color  = args.hover_color,            parent_hover_tint  = args.parent_hover_tint ~= N,
        shadow       = args.shadow,                 shadow_color       = args.shadow_color,
        widget_dist  = args.widget_dist or 0.8,     paint              = args.paint,
    }
end

local function _text_child(id, text, args, face_layer)
    return {
        --- basics
        style  = "text_widget",                                      T           = { x = args.label_x or 0.82, y = args.label_y or 0.36, w = args.label_w or 0.92, h = args.label_h or 0.26 },
        id     = id,                                                 face_layer  = face_layer or args.label_face_layer,

        --- hit test
        button    = N,                                               can_hover  = N,
        can_drag  = N,                                               can_click  = N,

        --- text settings
        text               = text or "",                             text_scale         = args.label_text_scale or 0.26,
        text_color         = args.label_color or ctl,                hover_color        = args.label_hover_color or co,
        font_type          = args.font_type,                         text_line_spacing  = args.text_line_spacing,
        parent_hover_tint  = args.label_parent_hover_tint ~= N,      text_align         = args.label_align or { x = "center", y = "middle" },
        text_padding       = args.label_padding or { x = 0, y = 0 }, text_maxw          = args.label_maxw or 1.4,
    }
end

-----------------------------
--- frame children
-----------------------------
local function _frame_children(id, args, layout, shadow_layer, face_layer)
    local frame, pieces      = Layout.frame(args, layout), args._folded_cfg.frame or {}
    local out,   child_args  = {},                         { tint = args.frame_tint or cw, parent_hover_tint = N, shadow = args.frame_shadow, shadow_layer = shadow_layer, face_layer = face_layer }

    local function piece_args(key, fit_axis)
        local p_args, arg_tints, piece = Common.clone_args(child_args), args.frame_tints or {}, pieces[key] or {}
        p_args.tint       = args["frame_" .. key .. "_tint"] or arg_tints[key] or piece.tint or p_args.tint
        p_args.fit_axis   = piece.fit_axis or fit_axis or p_args.fit_axis
        return p_args
    end
    local function add(key, fit_axis) if pieces[key] and pieces[key].quad_key then out[#out + 1] = _sprite_child(id .. "_frame_" .. key, "inter_btn_pack", pieces[key].quad_key, frame[key], piece_args(key, fit_axis)) end end

    add("top_left");            add("top");                  add("top_right")
    add("right", "height");     add("bottom_left")
    add("bottom");              add("bottom_right")
    add("fold")
    return out
end

-----------------------------
--- background children
-----------------------------
local function _paint_bg_child(id, args, cfg, T, prefix, shadow_layer, face_layer)
    local base_bg, child_args = args._folded_cfg.bg, Common.clone_args(args)
    local paint = cfg.paint or base_bg.paint
    child_args.bg_paint, child_args.paint_seed_entry = args[prefix .. "_paint"] or paint, Common.bg_paint_seed_entry(args)
    child_args.bg_fill_color = args[prefix .. "_fill_color"] or cfg.fill_color
    child_args.bg_shadow = args[prefix .. "_shadow"]; if child_args.bg_shadow == nil then child_args.bg_shadow = cfg.shadow end
    child_args.bg_shadow_color = args[prefix .. "_shadow_color"] or cfg.shadow_color

    local child = PaintRect.build(id, child_args)
    child.id, child.T = id .. "_" .. prefix, T
    child.shadow_layer, child.face_layer = shadow_layer, face_layer
    child.paint_alpha = args[prefix .. "_paint_alpha"] or cfg.paint_alpha
    return child
end

local function _bg_child(id, args, layout, shadow_layer, face_layer)
    local bg = args._folded_cfg.bg;                                  if not bg then return end
    return _paint_bg_child(id, args, bg, Layout.bg_T(args, layout), "bg", shadow_layer, face_layer)
end

local function _bg_underlay_child(id, args, layout, shadow_layer, face_layer)
    local bg = args._folded_cfg.bg_underlay;                          if not Common.bg_underlay_enabled(args) then return end
    return _paint_bg_child(id, args, bg, Layout.bg_underlay_T(args, layout), "bg_underlay", shadow_layer, face_layer)
end

-----------------------------
--- child list
-----------------------------
function M.build(id, args, layout, shadow_layer, face_layer)
    local label_args = Common.clone_args(args)
    for _, key in ipairs(LABEL_LAYOUT_KEYS) do label_args[key] = layout[key] end
    if label_args.label_padding then label_args.label_padding = Layout.scale_T(label_args.label_padding, layout.group_scale) end

    local children, bg_underlay_child = {}, _bg_underlay_child(id, args, layout, shadow_layer, face_layer)
    if bg_underlay_child then children[#children + 1] = bg_underlay_child end

    local bg_child = _bg_child(id, args, layout, shadow_layer, face_layer)
    if bg_child then children[#children + 1] = bg_child end

    local underlay = args._folded_cfg.mask_underlay
    if Common.mask_underlay_enabled(args) then children[#children + 1] = _sprite_child(id .. "_mask_underlay", "inter_btn_pack", underlay.quad_key, Layout.mask_underlay_T(args, layout), { fit_axis = args.mask_underlay_fit_axis or underlay.fit_axis, tint = args.mask_underlay_tint or underlay.tint, paint = args.mask_underlay_paint or underlay.paint, parent_hover_tint = N, shadow_layer = shadow_layer, face_layer = face_layer }) end

    local mask = args._folded_cfg.mask
    if mask then children[#children + 1] = _sprite_child(id .. "_mask", "inter_btn_pack", mask.quad_key, Layout.mask_T(args, layout), { fit_axis = args.mask_fit_axis or mask.fit_axis, tint = args.mask_tint or mask.tint, parent_hover_tint = N, shadow_layer = shadow_layer, face_layer = face_layer }) end

    for _, child in ipairs(_frame_children(id, args, layout, shadow_layer, face_layer)) do children[#children + 1] = child end

    children[#children + 1] = _sprite_child(id .. "_icon", "card_pawn_icon_pack", args.icon_quad_key or "hold_one", Layout.icon_T(args, layout), { tint = args.icon_tint or ccrm, hover_color = args.icon_hover_color or co, shadow_layer = shadow_layer, face_layer = face_layer })
    children[#children + 1] = _text_child(id .. args._folded_cfg.base.label_suffix, args.label, label_args, face_layer)

    local anchor = args._folded_cfg.frame.anchor
    if args.anchor_sprite ~= N then children[#children + 1] = _sprite_child(id .. "_anchor", "inter_btn_pack", args.anchor_quad_key or anchor.quad_key, Layout.anchor_sprite_T(args, layout), { tint = args.anchor_tint or cw, parent_hover_tint = N, shadow_layer = shadow_layer, face_layer = face_layer }) end
    return children
end

return M
