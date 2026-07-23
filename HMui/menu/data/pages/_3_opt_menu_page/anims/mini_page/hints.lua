local ChildFadeTree = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")
local Common        = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.common")
local Settings      = require("HMui.menu.data.pages._3_opt_menu_page.anims.mini_page.settings")

local START, HINT = Settings.START, Settings.HINT
local N = false

local M = {}

-----------------------------
--- helpers
-----------------------------
local function _uses_hint_enter_fade(child) return child.config and child.config.renderer == "hint_btn" and child.config.hint_enter_fade ~= N end
local function _uses_hint_enter_wipe(child) return child.config and child.config.renderer == "hint_btn" and child.config.hint_enter_wipe end
local function _set_wipe_tree(child, value) if not child then return end; child.fx_mask, child.fx_mask_dir = value, 1; for _, sub in ipairs(child.children or {}) do _set_wipe_tree(sub, value) end end
local function _fade_wipe_tree(gm, child, time) if not child then return end; Common.ease(gm, child, "fx_mask", 0, time, "lerp"); for _, sub in ipairs(child.children or {}) do _fade_wipe_tree(gm, sub, time) end end

-----------------------------
--- hint buttons
-----------------------------
--- Helper: fade child
local function _fade_child(gm, child)
    if _uses_hint_enter_wipe(child) then
        _set_wipe_tree(child, 1)
        Common.after(gm, Common.mini_at(START.textfx + 0.18), function() _fade_wipe_tree(gm, child, HINT.fade_time); return true end)
    end
    if _uses_hint_enter_fade(child) then
        ChildFadeTree.set_tree_alpha(child, 0)
        Common.after(gm, Common.mini_at(START.textfx), function() ChildFadeTree.fade_tree_in(child, gm, HINT.fade_time); return true end)
    end
    M.fade_in(gm, child)
end

function M.fade_in(gm, mini)
    for _, child in ipairs((mini and mini.children) or {}) do _fade_child(gm, child) end
    for _, fx in ipairs((mini and mini.page_card_textfx) or {}) do _fade_child(gm, fx) end
end

return M
