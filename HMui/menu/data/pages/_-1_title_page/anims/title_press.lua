local _title_path = "HMui.menu.data.pages._-1_title_page."
local _anim_path  = _title_path .. "anims."

local Chopsticks  = require(_anim_path  .. "decorators.chopsticks")
local KanjiParts  = require(_anim_path  .. "decorators.kanji_parts")
local Common      = require(_anim_path  .. "common")
local HatDrop     = require(_anim_path  .. "decorators.hat_drop")
local PressAlpha  = require(_title_path .. "preparation.press_alpha_anim")
local RiceBall    = require(_anim_path  .. "decorators.rice_ball")
local PrepFX      = require(_title_path .. "preparation.shader_fx")
local Timeline    = require(_anim_path  .. "timeline")

local _find = Common.find

local M = {}

local press_art_ids = {
    "title_decorator_chef_hat_mask",  "title_decorator_chef_hat_pad", "title_decorator_chef_hat",
    "title_decorator_chop_down",
    "title_decorator_chop_up",
    "title_decorator_rice_ball_mask", "title_decorator_rice_ball_sea_weed", "title_decorator_rice_ball_line",
}

----------------------------------------------
--- Helper: _press_widgets
----------------------------------------------
local function _press_widgets(root)
    local rice = {}
    rice[#rice + 1] = _find(root, "title_decorator_rice_ball_mask")
    rice[#rice + 1] = _find(root, "title_decorator_rice_ball_sea_weed")
    rice[#rice + 1] = _find(root, "title_decorator_rice_ball_line")

    return {
        chef_hat_mask  = _find(root, "title_decorator_chef_hat_mask"),
        chef_hat_pad   = _find(root, "title_decorator_chef_hat_pad"),
        chef_hat       = _find(root, "title_decorator_chef_hat"),
        chop_down      = _find(root, "title_decorator_chop_down"),
        chop_down_dec  = _find(root, "title_decorator_chop_down_dec"),
        chop_up        = _find(root, "title_decorator_chop_up"),
        chop_up_dec    = _find(root, "title_decorator_chop_up_dec"),
        rice           = rice,
    }
end

----------------------------------------------
--- Helper: _hide_old_press_art
----------------------------------------------
local function _hide_old_press_art(gm, ctx)
    for _, id in ipairs(press_art_ids) do
        local widget = Common.find_in_list(ctx and ctx.old_children, id)
        if widget then Common.ease(gm, widget, "draw_alpha", 0, Timeline.stage2.old_press_fade, "lerp") end
    end
end

----------------------------------------------
--- main: enter
----------------------------------------------
function M.enter(gm, panel, _, ctx)
    PrepFX.stop(gm)
    PressAlpha.stop(gm, ctx and ctx.old_children, Timeline.stage2.old_press_fade)
    local root = panel and panel.widget;     if not root then return end
    local widgets = _press_widgets(root)

    _hide_old_press_art(gm, ctx)
    KanjiParts.title_enter(gm, panel, ctx)
    HatDrop.start(gm, widgets)
    RiceBall.start(gm, widgets.rice)
    Chopsticks.start(gm, widgets)
end

return M
