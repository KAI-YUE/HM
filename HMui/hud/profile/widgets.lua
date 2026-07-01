local Layout = require("HMui.hud.cfg_data.layout")
local Theme  = require("HMui.hud.cfg_data.theme")
local Common = require("HMui.hud.common")

local Y, N = true, false

local M = {}

local LAYER   = Layout.layer
local PROFILE = Theme.profile or {}

-----------------------------
--- strokes
-----------------------------
local function _profile_strokes(strokes)
    local out = {}
    for i, s in ipairs(strokes) do out[i] = type(s) == "table" and Common.copy_T(s) or { quad_key = s, x = 0, y = 0, w = 1, h = 1, r = 0 }; if type(s) == "table" then out[i].quad_key = s.quad_key end end
    return out
end

local function _profile_stroke_color(side, pass, fallback)
    local stroke = PROFILE.stroke or {}
    local color  = stroke[side]
    if type(color) == "table" and color[1] then return color end
    if type(color) == "table" then return color[pass] or fallback end
    return color or fallback
end

local function _profile_stroke_shadow_opts(shadow, face_layer, shadow_layer)
    local out = { shadow = shadow.enabled ~= N, shadow_color = shadow.color or { 0, 0, 0, 0.28 }, shadow_parallax = shadow.shadow_parallax, widget_dist = shadow.widget_dist or 0.45, stroke_shadow_order = shadow.order, no_press_squash = Y }
    if shadow.order ~= "per_stroke" then out.shadow_layer, out.face_layer = shadow_layer, face_layer end
    return out
end

-----------------------------
--- contour
-----------------------------
local function _profile_mask_preview_T(T, cfg)
    if cfg.relative ~= N then return { x = T.x + (cfg.x or 0)*T.w, y = T.y + (cfg.y or 0)*T.h, w = (cfg.w or 1)*T.w, h = (cfg.h or 1)*T.h, r = cfg.r } end
    return { x = T.x + (cfg.x or 0), y = T.y + (cfg.y or 0), w = cfg.w or T.w, h = cfg.h or T.h, r = cfg.r }
end

local function _profile_mask_preview_fit(T, cfg) local out = _profile_mask_preview_T(T, cfg); if not cfg.h and cfg.fit_axis == "width" then out.h = nil end; return out end

local function _profile_contour_preview(T)
    local cfg = Layout.profile_mask and Layout.profile_mask.contour; if not (cfg and cfg.draw ~= N) then return end
    return Common.sprite(_profile_mask_preview_fit(T, cfg), cfg.atlas_key or "hud_pack", cfg.quad_key or "profile_outer", cfg.tint or { 1, 1, 1, 1 }, LAYER.profile_picture + 1, "hud_profile_contour", { fit_axis = cfg.fit_axis or "none" })
end

-----------------------------
--- widgets
-----------------------------
function M.widgets(side, stroke_color)
    local T            = Common.profile_T(side)
    local out, shadow  = {}, PROFILE.stroke_shadow or {}
    local back_shadow  = _profile_stroke_shadow_opts(shadow, LAYER.profile_back, LAYER.profile_back)
    local front_shadow = _profile_stroke_shadow_opts(shadow, LAYER.profile_front, LAYER.profile_picture)
    out[#out + 1] = Common.stroke_child(T, _profile_strokes(Layout.profile_strokes.back), _profile_stroke_color(side, "back", stroke_color), LAYER.profile_back, back_shadow)
    out[#out + 1] = _profile_contour_preview(T)
    out[#out + 1] = Common.stroke_child(T, _profile_strokes(Layout.profile_strokes.front), _profile_stroke_color(side, "front", stroke_color), LAYER.profile_front, front_shadow)
    return out
end

return M
