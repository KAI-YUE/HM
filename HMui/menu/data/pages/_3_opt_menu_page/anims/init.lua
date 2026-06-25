local Textfx    = require("HMui.menu.data.pages._3_opt_menu_page.anims.anim_textfx")
local MiniPage  = require("HMui.menu.data.pages._3_opt_menu_page.anims.anim_mini_page")
local Tabs      = require("HMui.menu.data.pages._3_opt_menu_page.tabs")

local M = {}

--- Helper: _sync_tab_state
local function _sync_tab_state(gm, panel)
    local state = (gm and gm.opt_menu_tab_state) or Tabs.default_state()
    if gm then gm.opt_menu_tab_state = state end
    if panel then panel.opt_tab_state = state end
end

--- main: enter animation
function M.enter(gm, panel, page, ctx)
    local root = panel and panel.widget
    _sync_tab_state(gm, panel)
    MiniPage.fade_in(gm, panel and panel.attached_panel, root)
    Textfx.fade_in_back(gm, ctx)
end

return M
