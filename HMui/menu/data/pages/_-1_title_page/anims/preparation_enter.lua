local KanjiParts = require("HMui.menu.data.pages._-1_title_page.anims.decorators.kanji_parts")
local Mark2Anim  = require("HMui.menu.data.pages._-1_title_page.preparation.mark2_anim")
local PressAlpha = require("HMui.menu.data.pages._-1_title_page.preparation.press_alpha_anim")
local ShaderFX   = require("HMui.menu.data.pages._-1_title_page.preparation.shader_fx")

local M = {}

----------------------------------------------
--- enter
----------------------------------------------
function M.enter(gm, panel)
    ShaderFX.start(gm)
    KanjiParts.preparation_enter(gm, panel)
    Mark2Anim.start(gm, panel and panel.widget)
    PressAlpha.start(gm, panel and panel.widget)
end

return M
