local C      = require("HMfns.animate.color.color_const")
local Layout = require("HMui.hud.cfg_data.layout")

local cw    = C.WHITE
local Y, N  = true, false

local M = {}

-----------------------------
--- table
----------------------------
function M.with(t, opts) for k, v in pairs(opts or {}) do t[k] = v end; return t end

-----------------------------
--- transforms
----------------------------
function M.copy_T(T)                 return { x = T.x, y = T.y, w = T.w, h = T.h, r = T.r, scale = T.scale } end
function M.padded_T(T, pad, keep_h)  local out = { x = T.x + (pad.x or 0), y = T.y + (pad.y or 0), w = T.w + (pad.w_pad or 0) }; if keep_h ~= N then out.h = T.h + (pad.h_pad or 0) elseif pad.h_pad and T.h then out.w = out.w + pad.h_pad*T.w/T.h end; return out end
function M.pass_T(T, pass)           local out = M.padded_T(T, pass or {}, N); if pass and pass.wh_ratio then out.h = out.w/(pass.wh_ratio or 1) end; return out end
function M.pass_fit(pass)            return pass and pass.wh_ratio and { fit_axis = "none" } or { fit_axis = "width" } end
function M.profile_T(side)           return M.copy_T(Layout.profile[side]) end

--- Helper: hud root T
local function _hud_T_cfg(side)
    local cfg, side_cfg = Layout.hud or {}, Layout.hud and Layout.hud[side] or {}
    return cfg, side_cfg or {}
end

function M.apply_hud_T(T, side)
    local cfg, side_cfg = _hud_T_cfg(side)
    T.x, T.y = (T.x or 0) + (cfg.x or 0) + (side_cfg.x or 0), (T.y or 0) + (cfg.y or 0) + (side_cfg.y or 0)
    T.scale = (T.scale or 1) * (cfg.scale or 1) * (side_cfg.scale or 1)
    return T
end

-----------------------------
--- assets
----------------------------
function M.fit_h(gm, atlas_key, quad_key, w)
    local atlas = gm and gm.T_atlas and gm.T_atlas[atlas_key]; if not (atlas and w) then return end
    local ok, quad = pcall(atlas.get_quad, atlas, quad_key);  if not ok then return end
    local _, _, qw, qh = quad:getViewport();                  if not (qw and qh and qw > 0) then return end
    return w*qh/qw
end

-----------------------------
--- widgets
----------------------------
function M.sprite(T, atlas, quad, tint, order, id, opts)
    tint = tint or cw
    return M.with({ style = "sprite_in_page", renderer = "single_sprite", id = id, atlas_key = atlas, quad_key = quad, sprite_mask_key = N, hover_face_shader = N, hover_mask_shader = N, shadow = N, button = N, T = T, tint = tint, sprite_color = tint, draw_order = order, can_hover = N, can_collide = N, no_press_squash = true, fit_axis = "none" }, opts)
end

function M.stroke_child(T, strokes, color, order, opts) return M.with({ style = "stroke", renderer = "stroke", fit_axis = "none", T = T, atlas_key = "ui_pack", fill_color = N, stroke_color = color, draw_order = order, strokes = strokes, can_hover = N, can_collide = N }, opts) end

-----------------------------
--- panel
----------------------------
function M.panel_T(gm, side)
    local RT, cfg = gm._room.T or { w = 24, h = 13.5 }, Layout.panel[side]
    local h = cfg.h or M.fit_h(gm, "ui_pack", "panel_1", cfg.w)
    if side == "foe" then return M.apply_hud_T({ x = RT.w - cfg.x_from_right, y = cfg.y, w = cfg.w, h = h }, side) end
    return M.apply_hud_T({ x = cfg.x, y = RT.h - cfg.y_from_bottom, w = cfg.w, h = h }, side)
end

--- Helper: child x
local function _child_x(cfg, parent_T) if cfg.x_from_right and parent_T then return parent_T.w - cfg.x_from_right - cfg.w end; return cfg.x or 0 end

function M.panel_2_T(gm, cfg, parent_T) return { x = _child_x(cfg, parent_T), y = cfg.y, w = cfg.w, h = cfg.h or M.fit_h(gm, "ui_pack", "panel_2", cfg.w) } end

return M
