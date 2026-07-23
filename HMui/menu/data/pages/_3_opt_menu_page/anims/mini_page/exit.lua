local Common   = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.common")
local Polygon  = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.polygon")
local Settings = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.settings")

local EXIT = Settings.EXIT

local M = {}

-----------------------------
--- pull helpers
-----------------------------
local function _pull_page(gm, page)
    if not page then return end
    Common.ease_exit(gm, page, "draw_offset_x", (page.draw_offset_x or 0) + (EXIT.pull_to.x or 0), EXIT.pull_duration, "sine")
    Common.ease_exit(gm, page, "draw_offset_y", (page.draw_offset_y or 0) + (EXIT.pull_to.y or 0), EXIT.pull_duration, "sine")
end

local function _pull_split_stroke(gm, root)
    local split = root and root.config and root.config.split;       if not split then return end
    Common.ease_exit(gm, split, "y", (split.y or 0) + EXIT.curtain_pull_y, EXIT.pull_duration, "sine")
end

-----------------------------
--- pull out
-----------------------------
function M.pull_out(gm, mini, root)
    _pull_page(gm, mini)
    for _, child in ipairs((mini and mini.page_child_widgets) or {}) do if child.config and (child.config.id == "opt_menu_mini_page" or child.config.id == "opt_cascade_mini_page") then _pull_page(gm, child) end end
    Polygon.pull_curtain(gm, root)
    _pull_split_stroke(gm, root)
    return EXIT.pull_duration
end

return M
