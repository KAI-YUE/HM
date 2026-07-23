local Spring  = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.spring")
local Polygon = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.polygon")
local Hints   = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.hints")
local Reveal  = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.reveal")
local Exit    = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.exit")

local M = {}

-------------------------------------
--- fade_in
-------------------------------------
function M.fade_in(gm, mini, root)
    if not mini then return end

    if mini.config and mini.config.id == "opt_mini_pages_root" then Spring.root(gm, mini) else Spring.mini_page(gm, mini) end
    Spring.mini_pages(gm, mini)
    Spring.gear(gm, mini)
    Spring.tab_hints(gm, mini)
    Hints.fade_in(gm, mini)
    Polygon.fade_curtain(gm, root)
    Reveal.textfx(gm, mini)
end

--------------------------------------
--- pull_out
--------------------------------------
function M.pull_out(gm, mini, root) return Exit.pull_out(gm, mini, root) end

return M
