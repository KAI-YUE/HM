local C         = require("HMfns.animate.color.color_const")
local HMPanel   = require("HMEng.ui_actors.hm_panel")
local Layout    = require("HMui.hud.layout")
local Theme     = require("HMui.hud.theme")
local Common    = require("HMui.hud.common")
local Profile   = require("HMui.hud.profile")
local Bars      = require("HMui.hud.bars")
local Seam      = require("HMui.hud.seam")
local Parallax  = require("HMui.hud.parallax")

local _sprite   = Common.sprite
local _pass_T   = Common.pass_T
local _copy_T   = Common.copy_T

local crm, cw = C.CREAM, C.WHITE

local Y, N = true, false

local M = {}

local LAYER = Layout.layer
local PANEL, PROFILE = Theme.panel or {}, Theme.profile or {}
local ICONS, BAR_BG =  Theme.icons or {}, Theme.bar_bg or {}

-----------------------------
--- create panel
----------------------------
--- Helper: push all
local function _push_all(dst, src) for _, v in ipairs(src or {}) do dst[#dst + 1] = v end end

--- Helper: panel args
local function _panel_args(gm, side)
    local foe,          stroke_color  = (side == "foe"),            PROFILE.stroke and PROFILE.stroke[side] or cw
    local panel_T,      panel_2       = Common.panel_T(gm, side),   Layout.panel_2
    local panel_2_T                   = Common.panel_2_T(gm, panel_2)
    local panel_1_T,    panel_pass    = { x = 0, y = 0, w = panel_T.w, h = panel_T.h }, Layout.panel_pass or {}
    local panel_2_pass, panel_shadow  = Layout.panel_2_pass or {},                      { shadow = PANEL.shadow ~= N, shadow_color = PANEL.shadow_color or { 0, 0, 0, 0.28 }, widget_dist = PANEL.widget_dist or 1.25, shadow_layer = PANEL.shadow_layer, face_layer = PANEL.face_layer }
    local icon_T,       bar_bg        = Layout.icons,                                   Layout.bar_bg
    
    local children = {
        _sprite(_pass_T(panel_1_T, panel_pass),                         "hud_pack", "panel_1", PANEL.pass_tint or crm, LAYER.panel - 1, "hud_panel_pass", Common.with(Common.with({}, panel_shadow), Common.pass_fit(panel_pass))),
        _sprite({ x = 0, y = 0, w = panel_T.w },                        "hud_pack", "panel_1", PANEL.base_tint or cw,  LAYER.panel, "hud_panel_1", { fit_axis = "width" }),
        _sprite(_pass_T(panel_2_T, panel_2_pass),                       "hud_pack", "panel_2", PANEL.detail_pass_tint or PANEL.pass_tint or crm, LAYER.panel, "hud_panel_2_pass", Common.pass_fit(panel_2_pass)),
        _sprite({ x = panel_2_T.x, y = panel_2_T.y, w = panel_2_T.w },  "hud_pack",  "panel_2", PANEL.detail_tint or PANEL.base_tint or cw, LAYER.panel + 1, "hud_panel_2", { fit_axis = "width" }),
    }

    local profile_icon = PROFILE.icon and PROFILE.icon[side] or (foe and "chat" or "chef_hat")

    _push_all(children, Profile.widgets(side, stroke_color))
    _push_all(children, {
        _sprite(_copy_T(icon_T.profile[side]), "icon_pack", profile_icon,              nil, LAYER.icon, "hud_profile_icon"),
        _sprite(_copy_T(icon_T.hp),            "icon_pack", ICONS.hp or "heart",       nil, LAYER.icon, "hud_hp_icon"),
        _sprite(_copy_T(icon_T.full),          "icon_pack", ICONS.full or "muffin",    nil, LAYER.icon, "hud_full_icon"),
        _sprite(_copy_T(icon_T.money),         "icon_pack", ICONS.money or "coin",     nil, LAYER.icon, "hud_money_icon"),
        _sprite(_copy_T(bar_bg.hp),            "ui_pack",   "btn_mask",                BAR_BG.hp or { 1, 1, 1, 0.46 }, LAYER.bar - 1, "hud_hp_bar_bg"),
        _sprite(_copy_T(bar_bg.full),          "ui_pack",   "btn_mask", BAR_BG.full or { 1, 1, 1, 0.46 }, LAYER.bar - 1, "hud_full_bar_bg"),
    })

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
    local p2, p2s = Layout.panel_2, Layout.panel_2_seam or {}

    panel.hud_side, panel.hud_stats = side, stats
    panel.hud_profile_T             = Common.profile_T(side)

    panel.hud_bars = {
        Bars.hud_bar(Layout.bars[1]),
        Bars.hud_bar(Layout.bars[2]),
    }

    Parallax.apply_panel(panel)
    Seam.attach(panel)
    Seam.attach(panel, Seam.cfg(Common.panel_2_T(gm, p2), p2s), LAYER.panel + 2)
    Bars.attach_draw(panel)
    return panel
end

M.attach_profile_draw = Profile.attach_profile_draw
M.LAYER  = LAYER
M.Layout = Layout
M.Theme  = Theme

return M
