local Motion    = require("HMEng.ui_actors.common.motion")
local Common    = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.common")
local Settings  = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.settings")

local START, FROM, DILATION, SPRING, ENTER = Settings.START, Settings.FROM, Settings.DILATION, Settings.SPRING, Settings.ENTER
local _spring_draw_offset = Motion.spring_draw_offset

local M = {}

-----------------------------
--- helpers
-----------------------------
local function _spring_draw_tree(gm, node, key, from, spring, delay, queue)
    _spring_draw_offset(gm, node, key, from, spring, delay, queue)
    for _, child in ipairs((node and node.children) or {}) do _spring_draw_tree(gm, child, key, from, spring, delay, queue) end
end
local function _tab_header_spring() return FROM.tab_header, Common.dilated_spring(SPRING.mini, DILATION.mini), Common.mini_at(START.tab_header) end

-----------------------------
--- mini pages
-----------------------------
local function _spring_mini_page(gm, mini) local from, spring, at = _tab_header_spring(); _spring_draw_offset(gm, mini, "_opt_menu_mini_page_enter", from, spring, at, ENTER.queue) end

function M.root(gm, root) _spring_draw_offset(gm, root, "_opt_mini_pages_root_enter", FROM.root, Common.dilated_spring(SPRING.mini, DILATION.mini), Common.mini_at(START.root), ENTER.queue) end
function M.mini_page(gm, mini) return _spring_mini_page(gm, mini) end

function M.mini_pages(gm, node)
    for _, child in ipairs((node and node.page_child_widgets) or {}) do
        if child.config and child.config.id == "opt_menu_mini_page"    then _spring_mini_page(gm, child) end
        if child.config and child.config.id == "opt_cascade_mini_page" then _spring_draw_offset(gm, child, "_opt_menu_cascade_mini_page_enter", FROM.cascade, Common.dilated_spring(SPRING.mini, DILATION.mini), Common.mini_at(START.cascade), ENTER.queue) end
        M.mini_pages(gm, child)
    end
end

-----------------------------
--- gear
-----------------------------
function M.gear(gm, node)
    for _, child in ipairs((node and node.page_child_widgets) or {}) do
        if child.config and child.config.quad_key == "gear" then _spring_draw_tree(gm, child, "_opt_menu_mini_gear_enter", FROM.gear, Common.dilated_spring(SPRING.gear, DILATION.gear), Common.mini_at(START.gear), ENTER.queue) end
        M.gear(gm, child)
    end
end

-----------------------------
--- tab hint buttons
-----------------------------
function M.tab_hints(gm, node)
    for _, child in ipairs((node and node.children) or {}) do
        if child.config and child.config.opt_tab_cut_in_sync then local from, spring, at = _tab_header_spring(); _spring_draw_tree(gm, child, "_opt_menu_tab_hint_enter", from, spring, at, ENTER.queue) end
        M.tab_hints(gm, child)
    end
end

return M
