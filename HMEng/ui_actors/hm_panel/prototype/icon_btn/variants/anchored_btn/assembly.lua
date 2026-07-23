local IconBtn = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Cfg     = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.anchored_btn.anchored_btn_type1_cfg")

local Y, N = true, false

local S = Cfg.base

local M = {}

--- Helper: sprite child
local function _sprite_child(id, atlas_key, quad_key, T, args)
    args = args or {}
    local tint = args.tint
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
        widget_dist  = args.widget_dist or 0.8,
    }
end

--- Helper: text child
local function _text_child(id, text, args, face_layer)
    args = args or {}
    return {
        --- basics
        style = "text_widget",                      T = { x = args.label_x or Cfg.label.T.x, y = args.label_y or Cfg.label.T.y, w = args.label_w or Cfg.label.T.w, h = args.label_h or Cfg.label.T.h },
         id = id,                                   face_layer = face_layer or args.label_face_layer,

        --- hit test
        button   = N,                               can_hover = N,
        can_drag = N,                               can_click = N,

        --- text settings
        text        = text or "",                   text_scale = args.label_text_scale or Cfg.label.text_scale,
        text_color  = args.label_color or Cfg.label.text_color, hover_color = args.label_hover_color or Cfg.label.hover_color,
        
        parent_hover_tint = args.label_parent_hover_tint ~= N,
        text_align        = args.label_align or Cfg.label.align,
        text_padding      = args.label_padding or Cfg.label.padding,
        text_maxw         = args.label_maxw or Cfg.label.text_maxw,
    }
end

---_______________________________________
--- main: button config
---_______________________________________
function M.build(args)
    args = args or {}
    local id = args.id or "anchored_icon_btn"
    local shadow_layer, face_layer = args.shadow_layer or S.shadow_layer, args.face_layer or S.face_layer
    local P = Cfg.parts
    local btn = {
        --- basics
        id = id,                                    T = args.T or M.anchor_T(args.anchor_T, args),

        --- hit test
        button    = args.button ~= N,               can_hover      = args.can_hover ~= N,
        can_drag  = N,                              can_click      = args.can_click ~= N,
        hit_shape = "rect",                         hit_padding    = args.hit_padding or { x = 0.04, y = 0.08 },
        hook_fn   = args.hook_fn,                   hover_hook_fn  = args.hover_hook_fn,
 
        --- hover settings
        hover_tint   = args.hover_tint or 0,        click_visual_time = args.click_visual_time or 0.12,
        widget_dist  = args.widget_dist or 0.75,

        --- child widgets
        child_widgets = {
            _sprite_child(id .. "_mask",   P.mask.atlas_key,   P.mask.quad_key,   P.mask.T,   { tint = args.mask_tint or P.mask.tint, parent_hover_tint = N, shadow_layer = shadow_layer, face_layer = face_layer }),
            _sprite_child(id .. "_frame",  P.frame.atlas_key,  P.frame.quad_key,  P.frame.T,  { tint = args.frame_tint or P.frame.tint, parent_hover_tint = N, shadow = args.frame_shadow, shadow_layer = shadow_layer, face_layer = face_layer }),
            _sprite_child(id .. "_icon",   P.icon.atlas_key,   args.icon_quad_key or P.icon.quad_key, P.icon.T, { tint = args.icon_tint or P.icon.tint, hover_color = args.icon_hover_color or P.icon.hover_color, shadow_layer = shadow_layer, face_layer = face_layer }),
            _text_child(id .. S.label_suffix, args.label, args, face_layer),
            _sprite_child(id .. "_anchor", P.anchor.atlas_key, P.anchor.quad_key, P.anchor.T, { tint = args.anchor_tint or P.anchor.tint, parent_hover_tint = N, shadow_layer = shadow_layer, face_layer = face_layer }),
        },
    }

    btn.style = IconBtn(btn)
    return btn
end

---_______________________________________
--- main: anchored T
---_______________________________________
function M.anchor_T(T, args)
    args = args or {}; T = T or {}
    local cx, cy  = (T.x or 0) + 0.5*(T.w or 0),       (T.y or 0) + 0.5*(T.h or 0)
    local w,  h   = args.w or S.w,                     args.h or S.h
    local ax, ay  = args.anchor_x or S.anchor_cx,      args.anchor_y or S.anchor_cy
    local sx, sy  = args.x_shift or 0,                 args.y_shift or 0
    
    return { x = cx - ax + sx, y = cy - ay + sy, w = w, h = h }
end

---_______________________________________
--- main: anchor offset
---_______________________________________
function M.anchor_offset_T(T, args)
    T = T or {}
    local aT = M.anchor_T(T, args)
    return { x = aT.x - (T.x or 0), y = aT.y - (T.y or 0) }
end

M.anchor_offset = { x = S.anchor_cx, y = S.anchor_cy }
M.label_suffix  = S.label_suffix
M.type1_cfg     = Cfg

function M.label_id(id) return (id or "anchored_icon_btn") .. S.label_suffix end

return M
