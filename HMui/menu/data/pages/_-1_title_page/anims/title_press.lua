local Common     = require("HMui.menu.data.pages._-1_title_page.anims.common")
local HatDrop    = require("HMui.menu.data.pages._-1_title_page.anims.decorators.hat_drop")
local Chopsticks = require("HMui.menu.data.pages._-1_title_page.anims.decorators.chopsticks")
local KanjiParts = require("HMui.menu.data.pages._-1_title_page.anims.decorators.kanji_parts")
local RiceBall   = require("HMui.menu.data.pages._-1_title_page.anims.decorators.rice_ball")
local PrepFX     = require("HMui.menu.data.pages._-1_title_page.preparation.shader_fx")
local Timeline   = require("HMui.menu.data.pages._-1_title_page.anims.timeline")

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
    rice[#rice + 1] = Common.find(root, "title_decorator_rice_ball_mask")
    rice[#rice + 1] = Common.find(root, "title_decorator_rice_ball_sea_weed")
    rice[#rice + 1] = Common.find(root, "title_decorator_rice_ball_line")

    return {
        chef_hat_mask = Common.find(root, "title_decorator_chef_hat_mask"),
        chef_hat_pad  = Common.find(root, "title_decorator_chef_hat_pad"),
        chef_hat      = Common.find(root, "title_decorator_chef_hat"),
        chop_down = Common.find(root, "title_decorator_chop_down"),
        chop_down_dec = Common.find(root, "title_decorator_chop_down_dec"),
        chop_up = Common.find(root, "title_decorator_chop_up"),
        chop_up_dec = Common.find(root, "title_decorator_chop_up_dec"),
        rice = rice,
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
    local root = panel and panel.widget;     if not root then return end
    local widgets = _press_widgets(root)

    _hide_old_press_art(gm, ctx)
    KanjiParts.title_enter(gm, panel, ctx)
    HatDrop.start(gm, widgets)
    RiceBall.start(gm, widgets.rice)
    Chopsticks.start(gm, widgets)
end

return M
