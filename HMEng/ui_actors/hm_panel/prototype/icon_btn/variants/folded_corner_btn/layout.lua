local TextFit   = require("HMfns.utils.format.text_fit")
local Common    = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.common")

local max, min  = math.max, math.min

local Y, N = true, false

local M  = {}
local SCALE_LAYOUT_KEYS  = { "w", "h", "content_w", "content_h", "icon_x", "icon_y", "icon_w", "label_x", "label_y", "label_w", "label_h", "label_maxw", "label_text_scale", "raw_text_w" }
local SCALE_T_KEYS       = { "x", "y", "w", "h" }

--- Helpers: clamp | scale T
local function _clamp(v, min_v, max_v)  return min(max_v, max(min_v, v)) end
local function _scale_T(T, scale)       for _, key in ipairs(SCALE_T_KEYS) do if T[key] then T[key] = T[key]*scale end end; return T end

--- Helper: logical layout
local function _logical_layout(layout)
    local scale = layout.group_scale
    return {
        w          = layout.w/scale,          h          = layout.h/scale,
        content_w  = layout.content_w/scale,  content_h  = layout.content_h/scale }
end

-----------------------------
--- button layout
-----------------------------
function M.compute(args)
    local S = args._folded_cfg.layout

    local group_scale, text       = args.group_scale or S.group_scale,  args.label or ""
    local base_scale,  min_scale  = args.label_text_scale or 0.26,      args.label_min_text_scale or 0.20
    local icon_x,      icon_w     = args.icon_x or 0.18,                args.icon_w or 0.34
    local gap,         right_pad  = args.label_gap or 0.16,             args.right_pad or 0.32

    local raw_text_w = TextFit.estimated_w(text, { text_scale = base_scale, lang  = args.label_lang, char_w_factor  = args.label_char_w_factor or args.char_w_factor })

    local label_x,     max_w           = args.label_x or (icon_x + icon_w + gap),                                                   args.max_w or S.max_w
    local ideal_w,     mask            = icon_x + icon_w + gap + (args.label_w or raw_text_w) + right_pad,                          args._folded_cfg.mask
    local content_w,   content_h       = args.w or _clamp(ideal_w, args.min_w or S.min_w, max_w),                                   args.h or S.h
    local label_w,     affects_layout  = max(0.2, args.label_w or (content_w - label_x - right_pad)),                               args.mask_affects_layout
    local text_scale,  mask_axis       = raw_text_w > label_w and max(min_scale, base_scale * label_w/raw_text_w) or base_scale,    mask and (args.mask_fit_axis or mask.fit_axis)
    local w,           h               = content_w, content_h

    if mask then
        if affects_layout == nil then affects_layout = mask.affects_layout end
        if affects_layout and mask_axis ~= "height" then w = max(w, (args.mask_x or mask.x) + content_w*(args.mask_w_scale or mask.w_scale) + (args.mask_w_pad or mask.w_pad)) end
        if affects_layout and mask_axis ~= "width"  then h = max(h, (args.mask_y or mask.y) + (args.mask_h or content_h)*(args.mask_h_scale or mask.h_scale) + (args.mask_h_pad or mask.h_pad)) end
    end

    local out = {
        w                 = w,                      h                 = h,
        content_w         = content_w,              content_h         = content_h,
        icon_x            = icon_x,                 icon_y            = args.icon_y or 0.14,
        icon_w            = icon_w,
        label_x           = label_x,                label_y           = args.label_y or 0.36,
        label_w           = label_w,                label_h           = args.label_h or 0.26,
        label_maxw        = args.label_maxw or label_w,
        label_text_scale  = text_scale,             raw_text_w        = raw_text_w,
    }
    for _, key in ipairs(SCALE_LAYOUT_KEYS) do out[key] = out[key]*group_scale end
    out.group_scale = group_scale
    return out
end

-----------------------------
--- component transforms
-----------------------------
function M.button_T(args, layout)
    local scale, S = layout.group_scale, args._folded_cfg.layout

    if not args.T then return Common.anchor_T(args.anchor_T, {
        _folded_cfg  = args._folded_cfg,                       w         = layout.w,
        h            = layout.h,                               anchor_x  = (args.anchor_x or S.anchor_cx)*scale,
        anchor_y     = (args.anchor_y or S.anchor_cy)*scale,   x_shift   = args.x_shift,
        y_shift      = args.y_shift,
    }) end

    local T = Common.clone_args(args.T)

    if args.keep_T_size ~= Y then T.w, T.h = layout.w, layout.h end
    return T
end

----------------------------------
--- bg_T
----------------------------------
function M.bg_T(args, layout)
    local cfg, L  = args._folded_cfg, _logical_layout(layout)
    local bg, S   = cfg.bg, cfg.layout

    return _scale_T({
        x  = bg.x or 0,                 y  = bg.y or 0,
        w  = bg.base_w*(L.w/S.min_w) + (bg.w_extra or 0),
        h  = bg.base_h*(L.h/S.h) + (bg.h_extra or 0),
    }, layout.group_scale)
end

-----------------------------------
--- bg_underlay_T
-----------------------------------
function M.bg_underlay_T(args, layout)
    local cfg, base = args._folded_cfg.bg_underlay, M.bg_T(args, layout)
    local scale     = layout.group_scale
    local w_scale   = args.bg_underlay_w_scale or cfg.w_scale
    local h_scale   = args.bg_underlay_h_scale or cfg.h_scale
    local w         = base.w*w_scale + (args.bg_underlay_w_pad or cfg.w_pad)*scale
    local h         = base.h*h_scale + (args.bg_underlay_h_pad or cfg.h_pad)*scale
    return {
        x = base.x - 0.5*(w - base.w) + (args.bg_underlay_x or cfg.x)*scale,
        y = base.y - 0.5*(h - base.h) + (args.bg_underlay_y or cfg.y)*scale,
        w = w, h = h,
    }
end

local function _mask_layer_T(args, layout, cfg, key)
    local L     = _logical_layout(layout)
    local axis  = args[key .. "_fit_axis"] or cfg.fit_axis
    local out   = {
        x  = args[key .. "_x"] or cfg.x,   y  = args[key .. "_y"] or cfg.y,
        w  = L.content_w*(args[key .. "_w_scale"] or cfg.w_scale) + (args[key .. "_w_pad"] or cfg.w_pad),
    }

    if axis ~= "width" then out.h = (args[key .. "_h"] or L.content_h)*(args[key .. "_h_scale"] or cfg.h_scale) + (args[key .. "_h_pad"] or cfg.h_pad) end
    if axis == "height" then out.w = nil end
    return _scale_T(out, layout.group_scale)
end

------------------------------------------------------------
--- mask_T | mask_underlay_T | icon_T | label_T
------------------------------------------------------------
function M.mask_T(args, layout)           return _mask_layer_T(args, layout, args._folded_cfg.mask, "mask") end
function M.mask_underlay_T(args, layout)  return _mask_layer_T(args, layout, args._folded_cfg.mask_underlay, "mask_underlay") end
function M.icon_T(args, layout)           return { x  = layout.icon_x,  y  = layout.icon_y, w  = layout.icon_w } end
function M.label_T(layout)                return { x  = layout.label_x,  y  = layout.label_y,  w  = layout.label_w,  h  = layout.label_h } end

function M.anchor_sprite_T(args, layout)
    local L, T, cfg = _logical_layout(layout), args.anchor_sprite_T, args._folded_cfg.frame.anchor
    T = T and Common.clone_args(T) or {
        x  = min(L.w - (args.anchor_sprite_right_gap or cfg.right_gap), args.anchor_sprite_x or cfg.x),
        y  = args.anchor_sprite_y or cfg.y,   w  = args.anchor_sprite_w or cfg.w,
    }
    return _scale_T(T, layout.group_scale)
end

function M.scale_T(T, scale) return _scale_T(Common.clone_args(T), scale) end

-----------------------------
--- frame layout
-----------------------------
--- Helpers: frame arg | piece arg 
local function _frame_arg(args, key, fallback) local frame = args.frame or {}; if frame[key] ~= nil then return frame[key] end; return args[key] or fallback end
local function _piece_arg(args, piece, key, fallback) return _frame_arg(args, piece .. "_" .. key, fallback) end

--- Helper: _piece_scale
local function _piece_scale(args, pieces, key, axis)
    local cfg = pieces[key] or {}
    local scale = _piece_arg(args, key, "scale", cfg.scale or 1)
    return _piece_arg(args, key, axis .. "_scale", cfg[axis .. "_scale"] or scale)
end

--- Helper: _scale_piece 
local function _scale_piece(args, pieces, key, T)
    if T.w then T.w = T.w*_piece_scale(args, pieces, key, "w") end
    if T.h then T.h = T.h*_piece_scale(args, pieces, key, "h") end
end

------------------------------
--- frame 
------------------------------
function M.frame(args, layout)
    local cfg                   = args._folded_cfg
    local scale, L              = layout.group_scale, _logical_layout(layout)
    local w, h                  = L.w, L.h
    local f                     = cfg.frame or {}
    local frame_w, frame_h      = args.frame_w or f.base_w, args.frame_h or f.base_h
    local top_left_w            = f.top_left and f.top_left.w_ratio and f.top_left.w_ratio*frame_h
    local top_right_w           = ((f.top_right and f.top_right.w_ratio) or 0.242009)*frame_h
    local top_w                 = _piece_arg(args, "top", "w", ((f.top and f.top.w_ratio) or 0.77)*frame_h)
    local top_draw_w            = top_w*_piece_scale(args, f, "top", "w")
    local top_gap               = _piece_arg(args, "top", "gap", f.top and f.top.gap or 0)
    local top_right_gap         = _piece_arg(args, "top_right", "gap", f.top_right and f.top_right.gap or -0.02)
    local bottom_left_w         = ((f.bottom_left and f.bottom_left.w_ratio) or 0.150685)*frame_h
    local bottom_right_w        = ((f.bottom_right and f.bottom_right.w_ratio) or 0.242009)*frame_h
    local right_h               = ((f.right and f.right.h_ratio) or 0.538813)*frame_h
    local right_w               = right_h*_piece_scale(args, f, "right", "h")*((f.right and f.right.wh_ratio) or 0.381356)
    local fold_w                = ((f.fold and f.fold.w_ratio) or 0.191781)*frame_h
    local fold_h                = fold_w/((f.fold and f.fold.wh_ratio) or 0.724138)
    local fold_draw_w           = fold_w*_piece_scale(args, f, "fold", "w")

    local out = {
        top_left      = {
            x  = _piece_arg(args, "top_left", "x", f.top_left and f.top_left.x or -0.04),
            y  = _piece_arg(args, "top_left", "y", f.top_left and f.top_left.y or -0.08),
            w  = _piece_arg(args, "top_left", "w", top_left_w or max(0.55, frame_w - top_right_w + 0.02)),
        },
        top           = {
            x  = w - top_draw_w - top_gap,
            y  = _piece_arg(args, "top", "y", f.top and f.top.y or -0.08),
            w  = top_w,
        },
        top_right     = {
            x  = w - top_right_w - top_right_gap,
            y  = _piece_arg(args, "top_right", "y", f.top_right and f.top_right.y or -0.03),
            w  = top_right_w,
        },
        right         = {
            x  = w - right_w - _piece_arg(args, "right", "gap", f.right and f.right.gap or 0),
            y  = _piece_arg(args, "right", "y", f.right and f.right.y or 0.17),
            h  = _piece_arg(args, "right", "h", right_h),
        },
        bottom_left   = {
            x  = _piece_arg(args, "bottom_left", "x", f.bottom_left and f.bottom_left.x or -0.04),
            y  = h - _piece_arg(args, "bottom_left", "gap_y", f.bottom_left and f.bottom_left.gap_y or 0.13),
            w  = bottom_left_w,
        },
        bottom        = {
            x  = bottom_left_w + _piece_arg(args, "bottom", "x_shift", f.bottom and f.bottom.x_shift or -0.04),
            y  = h - _piece_arg(args, "bottom", "gap_y", f.bottom and f.bottom.gap_y or 0.08),
            w  = max(0.55, frame_w - bottom_left_w - bottom_right_w + _piece_arg(args, "bottom", "w_extra", f.bottom and f.bottom.w_extra or 0.04)),
        },
        bottom_right  = {
            x  = w - bottom_right_w - _piece_arg(args, "bottom_right", "gap", f.bottom_right and f.bottom_right.gap or -0.02),
            y  = h - _piece_arg(args, "bottom_right", "gap_y", f.bottom_right and f.bottom_right.gap_y or 0.08),
            w  = bottom_right_w,
        },
        fold          = {
            x  = w - fold_draw_w - _piece_arg(args, "fold", "gap", f.fold and f.fold.gap or 0.12),
            y  = _piece_arg(args, "fold", "y", f.fold and f.fold.y or 0.23),
            w  = fold_w,
            h  = fold_h,
        },
    }
    for key, T in pairs(out) do _scale_piece(args, f, key, T); _scale_T(T, scale) end
    return out
end

return M
