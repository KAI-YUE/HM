local Theme, C  = require("HMui.hud.cfg_data.theme"), require("HMfns.animate.color.color_const")
local HMPanel   = require("HMEng.ui_actors.hm_panel")
local Layout    = require("HMui.hud.cfg_data.layout")
local Common    = require("HMui.hud.common")
local Profile   = require("HMui.hud.profile")
local Bars      = require("HMui.hud.bars")
local Parallax  = require("HMui.hud.parallax")

local _sprite   = Common.sprite
local _pass_T   = Common.pass_T
local _copy_T   = Common.copy_T

local crm, cw   = C.CREAM, C.WHITE

local Y, N = true, false

local M = {}

local LAYER            = Layout.layer
local PANEL,  PROFILE  = Theme.panel or {}, Theme.profile or {}
local L_icon           = LAYER.icon

-----------------------------
--- create panel
----------------------------
--- Helpers: push all | icon cfg | icon T | push icon pair
local function _push_all(dst, src)       for _, v in ipairs(src or {}) do dst[#dst + 1] = v end end
local function _icon_cfg(key, fallback)  local cfg = Layout.icon_style and Layout.icon_style[key] or fallback; if type(cfg) == "string" then return { quad_key = cfg } end; return cfg or { quad_key = fallback } end
local function _icon_T(T)                return { x = T.x, y = T.y, w = T.w, h = T.h, r = T.r, scale = T.scale } end
local function _icon_pass_T(T, pass)
    pass = pass or {}
    local out = { x = T.x + (pass.x or 0), y = T.y + (pass.y or 0), w = T.w + (pass.w_pad or 0), h = T.h and T.h + (pass.h_pad or 0) or nil, r = T.r, scale = T.scale }
    if pass.wh_ratio then out.h = out.w/(pass.wh_ratio or 1) end
    return out
end
local function _icon_pass_cfg(pass, cfg) local out = Common.with({}, pass or {}); return Common.with(out, cfg.pass or {}) end
local function _push_icon_pair(children, T, cfg, id, pass)
    local atlas, quad = cfg.atlas_key or "icon_pack", cfg.quad_key or cfg.key; if not quad then return end
    local pass_cfg = _icon_pass_cfg(pass, cfg)
    local fit_axis = cfg.fit_axis or T.fit_axis or "width"
    if pass_cfg and pass_cfg.enabled ~= N then children[#children + 1] = _sprite(_icon_pass_T(T, pass_cfg), pass_cfg.atlas_key or atlas, pass_cfg.quad_key or pass_cfg.key or quad, pass_cfg.tint or cfg.tint, pass_cfg.layer or L_icon - 1, id.."_pass", { fit_axis = pass_cfg.fit_axis or fit_axis }) end
    children[#children + 1] = _sprite(_icon_T(T), atlas, quad, cfg.tint, cfg.layer or L_icon, id, { fit_axis = fit_axis })
end

-----------------------------
--- temporary layout tuning
----------------------------
--- Helper: show part
local function _show_part(key)      local v = Layout.show and Layout.show[key]; if v == nil then return Y end; return v ~= N end
local function _show_profile(side)  local v = Layout.show and Layout.show.profile_visible and Layout.show.profile_visible[side]; if v == nil then return Y end; return v ~= N end

--- Helper: panel args
local function _panel_args(gm, side)
    local foe,          stroke_color  = (side == "foe"),                                PROFILE.stroke and PROFILE.stroke[side] or cw
    local panel_T,      panel_2       = Common.panel_T(gm, side),                       Layout.panel_2
    local panel_2_T                   = Common.panel_2_T(gm, panel_2, panel_T)
    local panel_1_T,    panel_pass    = { x = 0, y = 0, w = panel_T.w, h = panel_T.h }, Layout.panel_pass or {}
    local panel_2_pass, panel_shadow  = Layout.panel_2_pass or {},                      { shadow = PANEL.shadow ~= N, shadow_color = PANEL.shadow_color or { 0, 0, 0, 0.28 }, widget_dist = PANEL.widget_dist or 1.25, shadow_layer = PANEL.shadow_layer, face_layer = PANEL.face_layer }
    local icon_T,       icon_pass     = Layout.icons,                                   Layout.icon_pass
    
    local children = {
        _sprite(_pass_T(panel_1_T, panel_pass),                         "hud_pack", "panel_1_mask", PANEL.pass_tint or crm, LAYER.panel - 1, "hud_panel_pass", Common.with(Common.with({}, panel_shadow), Common.pass_fit(panel_pass))),
        _sprite({ x = 0, y = 0, w = panel_T.w },                        "hud_pack", "panel_1",      PANEL.base_tint or cw,  LAYER.panel, "hud_panel_1", { fit_axis = "width" }),
        _sprite(_pass_T(panel_2_T, panel_2_pass),                       "hud_pack", "panel_2_mask", PANEL.pass_tint or crm, LAYER.panel, "hud_panel_2_pass", Common.pass_fit(panel_2_pass)),
        _sprite({ x = panel_2_T.x, y = panel_2_T.y, w = panel_2_T.w },  "hud_pack", "panel_2",      PANEL.base_tint or cw, LAYER.panel + 1, "hud_panel_2", { fit_axis = "width" }),
    }

    -- local profile_icon = PROFILE.icon and PROFILE.icon[side] or (foe and "chat" or "chef_hat")

    _push_all(children, Profile.widgets(side, stroke_color))
    if _show_part("icons") then
        -- _push_icon_pair(children, icon_T.profile[side], _icon_cfg("profile", profile_icon), "hud_profile_icon", icon_pass)
        _push_icon_pair(children, icon_T.hp,    _icon_cfg("hp",    "heart"),  "hud_hp_icon",    icon_pass)
        _push_icon_pair(children, icon_T.full,  _icon_cfg("full",  "muffin"), "hud_full_icon",  icon_pass)
        _push_icon_pair(children, icon_T.money, _icon_cfg("money", "coin"),   "hud_money_icon", icon_pass)
    end

    return {
        style         = "empty_container",  T           = panel_T,
        can_hover     = N,                  can_collide = N,
        child_widgets = children,
    }
end

---_______________________________________
--- main: create panel
---_______________________________________
function M.create_panel(gm, side, stats)
    local panel   = HMPanel(gm, _panel_args(gm, side))

    panel.hud_side, panel.hud_stats = side, stats
    panel.hud_profile_T             = Common.profile_T(side)

    panel.hud_bars = _show_part("bars") and {
        Bars.hud_bar(Layout.bars[1]),
        Bars.hud_bar(Layout.bars[2]),
    } or {}

    Profile.attach_smudge_array(panel)
    Parallax.apply_panel(panel)
    Bars.attach_draw(panel)
    if not _show_profile(side) then panel.states.visible = N; if panel.widget then panel.widget.states.visible = N end end
    return panel
end

M.attach_profile_draw = Profile.attach_profile_draw
M.LAYER  = LAYER
M.Layout = Layout
M.Theme  = Theme

return M
