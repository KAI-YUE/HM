local Layout = require("HMui.hud.cfg_data.layout")
local Theme  = require("HMui.hud.cfg_data.theme")
local Common = require("HMui.hud.common")
local Mask   = require("HMui.hud.profile.mask")

local Y, N = true, false

local M = {}

local LAYER   = Layout.layer
local PROFILE = Theme.profile or {}

-----------------------------
--- color jitter
-----------------------------
--- Helper: hash
local function _hash(n) return (math.sin(n*12.9898 + 78.233)*43758.5453) % 1 end

--- Helper: lerp color
local function _lerp_color(a, b, t) return { (a[1] or 1) + ((b[1] or 1) - (a[1] or 1))*t, (a[2] or 1) + ((b[2] or 1) - (a[2] or 1))*t, (a[3] or 1) + ((b[3] or 1) - (a[3] or 1))*t, (a[4] or 1) + ((b[4] or 1) - (a[4] or 1))*t } end

--- Helper: stroke jitter color
local function _stroke_jitter_color(stroke, fallback, pass, i)
    local cfg = Layout.profile_stroke_color_jitter; if not (cfg and cfg.enabled ~= N) then return stroke.stroke_color or stroke.color or fallback end
    local t = _hash((cfg.seed or 0) + i*17 + (pass == "front" and 101 or 0))*(cfg.amount or 0.25)
    return _lerp_color(cfg.base or fallback, cfg.target or fallback, t)
end

-----------------------------
--- layer
-----------------------------
--- Helper: profile layer
local function _profile_layer(key, fallback) local layer = Layout.profile_layer or {}; return layer[key] or fallback end

-----------------------------
--- strokes
-----------------------------
--- Helper: _profile_strokes
local function _profile_strokes(strokes)
    local out = {}
    for i, s in ipairs(strokes) do if type(s) == "table" then out[i] = Common.with({}, s) else out[i] = { quad_key = s, x = 0, y = 0, w = 1, h = 1, r = 0 } end end
    return out
end

--- Helper: _profile_stroke_color
local function _profile_stroke_color(side, pass, fallback)
    local stroke = PROFILE.stroke or {}
    local color  = stroke[side]
    if type(color) == "table" and color[1] then return color end
    if type(color) == "table"              then return color[pass] or fallback end
    return color or fallback
end

--- Helper: pick bool
local function _pick_bool(v, fallback) if v ~= nil then return v end; return fallback end

--- Helper: profile_stroke_shadow_opts
local function _profile_stroke_shadow_opts(shadow, cfg, face_layer, shadow_layer)
    cfg = cfg or {}
    local out = { atlas_key = cfg.atlas_key or "hud_pack", shadow = _pick_bool(cfg.shadow, shadow.enabled ~= N), shadow_color = cfg.shadow_color or shadow.color or { 0, 0, 0, 0.28 }, shadow_parallax = cfg.shadow_parallax or cfg.parallax or shadow.shadow_parallax, widget_dist = cfg.widget_dist or shadow.widget_dist or 0.45, stroke_shadow_order = cfg.stroke_shadow_order or cfg.order or shadow.order, no_press_squash = _pick_bool(cfg.no_press_squash, Y) }
    if out.stroke_shadow_order ~= "per_stroke" then out.shadow_layer, out.face_layer = shadow_layer, face_layer end
    return out
end

--- Helper: profile stroke child opts
local function _profile_stroke_child_opts(opts, stroke, layer, id, i)
    local child_opts = Common.with({}, opts)
    child_opts.draw_order      = stroke.layer or stroke.draw_order or child_opts.draw_order or layer
    child_opts.shadow_color    = stroke.shadow_color or child_opts.shadow_color
    child_opts.shadow_parallax = stroke.shadow_parallax or stroke.parallax or child_opts.shadow_parallax
    child_opts.widget_dist     = stroke.widget_dist or child_opts.widget_dist
    child_opts.id              = id and (id.."_"..i) or child_opts.id
    return child_opts
end

--- Helper: push profile stroke widgets
local function _push_profile_stroke_widgets(out, T, strokes, color, layer, opts, id, pass)
    for i, stroke in ipairs(strokes or {}) do
        local child_opts = _profile_stroke_child_opts(opts, stroke, layer, id, i)
        out[#out + 1] = Common.stroke_child(T, _profile_strokes({ stroke }), _stroke_jitter_color(stroke, color, pass, i), layer, child_opts)
    end
end

-----------------------------
--- contour
-----------------------------
--- Helper: profile mask preview x
local function _profile_mask_preview_x(T, cfg, w, rel) if cfg.x_from_right then return T.x + T.w - cfg.x_from_right*rel - w end; return T.x + (cfg.x or 0)*rel end

--- Helper: profile_mask_preview_T
local function _profile_mask_preview_T(T, cfg)
    if cfg.relative ~= N then local w, h = (cfg.w or 1)*T.w, (cfg.h or 1)*T.h; return { x = _profile_mask_preview_x(T, cfg, w, T.w), y = T.y + (cfg.y or 0)*T.h, w = w, h = h, r = cfg.r } end
    local w, h = cfg.w or T.w, cfg.h or T.h; return { x = _profile_mask_preview_x(T, cfg, w, 1), y = T.y + (cfg.y or 0), w = w, h = h, r = cfg.r }
end

--- Helper: profile_mask_preview_fit
local function _profile_mask_preview_fit(T, cfg) local out = _profile_mask_preview_T(T, cfg); if not cfg.h and cfg.fit_axis == "width" then out.h = nil end; return out end

--- Helper: profile_contour_preview
local function _profile_contour_preview(T, cfg, id, i)
    if not (cfg and cfg.draw ~= N) then return end
    local layer = i and i > 1 and _profile_layer("contour_detail", 42) or _profile_layer("contour", LAYER.profile_front + 1)
    return Common.sprite(_profile_mask_preview_fit(T, cfg), cfg.atlas_key or "hud_pack", cfg.quad_key or "profile_outer", cfg.tint or { 1, 1, 1, 1 }, cfg.layer or layer, id, { fit_axis = cfg.fit_axis or "none", shadow = cfg.shadow, shadow_color = cfg.shadow_color, shadow_parallax = cfg.shadow_parallax or cfg.parallax, widget_dist = cfg.widget_dist })
end

--- Helper: push profile contour previews
local function _push_profile_contour_previews(out, T)
    local cfg = Layout.profile_mask and Layout.profile_mask.contour; if not cfg then return end
    if cfg[1] then for i, sub in ipairs(cfg) do out[#out + 1] = _profile_contour_preview(T, sub, "hud_profile_contour_"..i, i) end; return end
    out[#out + 1] = _profile_contour_preview(T, cfg, "hud_profile_contour")
end

--- Helper: profile_mask_preview
local function _profile_mask_preview(T, cfg, id)
    if not (cfg and cfg.draw ~= N) then return end
    return Common.sprite(_profile_mask_preview_fit(T, cfg), cfg.atlas_key or "hud_pack", cfg.quad_key or "hud_masks", cfg.tint or { 1, 1, 1, 0.42 }, cfg.layer or _profile_layer("mask", LAYER.profile_picture - 1), id, { fit_axis = cfg.fit_axis or "none", paint = cfg.paint })
end

--- Helper: push profile mask previews
local function _push_profile_mask_previews(out, T)
    local cfg = Layout.profile_mask; if not cfg then return end
    out[#out + 1] = _profile_mask_preview(T, cfg, "hud_profile_mask")
    for i, sub in ipairs(Mask.sub_cfgs(cfg, "extension")) do out[#out + 1] = _profile_mask_preview(T, sub, "hud_profile_mask_ext_"..i) end
end

-----------------------------
--- widgets
-----------------------------
function M.widgets(side, stroke_color)
    local T             = Common.profile_T(side)
    local out, shadow   = {}, PROFILE.stroke_shadow or {}
    local back_layer    = _profile_layer("back",  LAYER.profile_back)
    local front_layer   = _profile_layer("front", LAYER.profile_front)
    local back_cfg      = Layout.profile_strokes.back or {}
    local front_cfg     = Layout.profile_strokes.front or {}
    local back_shadow   = _profile_stroke_shadow_opts(shadow, back_cfg,  back_layer,  back_layer)
    local front_shadow  = _profile_stroke_shadow_opts(shadow, front_cfg, front_layer, _profile_layer("chara", LAYER.profile_picture))
    
    _push_profile_mask_previews(out, T)
    _push_profile_stroke_widgets(out, T, back_cfg,  _profile_stroke_color(side, "back", stroke_color),  back_layer,  back_shadow,  "hud_profile_stroke_back", "back")
    _push_profile_stroke_widgets(out, T, front_cfg, _profile_stroke_color(side, "front", stroke_color), front_layer, front_shadow, "hud_profile_stroke_front", "front")
    _push_profile_contour_previews(out, T)
    return out
end

return M
