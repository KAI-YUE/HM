local MenuTransitions = require("HMfns.animate.transitions.menu_transitions")
local Common          = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.common")
local Settings        = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.settings")

local START, ENTER = Settings.START, Settings.ENTER

local M = {}

-----------------------------
--- textfx
-----------------------------
function M.textfx(gm, node)
    if node and node.page_card_textfx then
        MenuTransitions.fade_in_textfx(gm, node, {
            bg_after_page_delay = Common.mini_at(START.textfx),
            text_after_bg_delay = 0.18,
            bg_fade_duration    = 0.24,
            text_fade_duration  = 0.36,
            stagger             = ENTER.textfx_stagger,
            lock                = 1.2,
        })
    end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do M.textfx(gm, child) end
end

return M
