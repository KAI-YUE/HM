local Motion = require("HMEng.ui_actors.common.motion")
local AnimUtils = require("HMfns.animate.transitions.anim_utils")
local ChildFadeTree = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")

-- local 
local _spring_draw_offset = Motion.spring_draw_offset

local _queue               = "save_menu_enter"
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end
local _mini_cut_in_delay   = 1
local _mini_start          = 0.18
local _mini_item_start     = 0.28
local _mini_item_stagger   = 0.2
local _mini_page_dilation  = 2
local _mini_item_dilation  = 2
local _mini_page_from      = { x = 2, y = -6.2 }
local _mini_item_from      = { x = 1.65, y = -4.8 }

local _mini_page_spring = {
    { t = 0.34, x =  0.10, y =  0.42, ease = "sine" },
    { t = 0.20, x = -0.05, y = -0.19, ease = "sine" },
    { t = 0.16, x =  0.025, y =  0.08, ease = "sine" },
    { t = 0.12, x =  0, y =  0, ease = "sine" },
}

local _mini_item_spring = {
    { t = 0.30, x =  0.12, y =  0.50, ease = "sine" },
    { t = 0.18, x = -0.07, y = -0.24, ease = "sine" },
    { t = 0.14, x =  0.035, y =  0.10, ease = "sine" },
    { t = 0.12, x = -0.015, y = -0.04, ease = "sine" },
    { t = 0.10, x =  0, y =  0, ease = "sine" },
}

local M = {}

---helper: _mini_at
local function _mini_at(delay) return _mini_cut_in_delay + delay end

---helper: _dilated_spring
local function _dilated_spring(spring, dilation)
    if (dilation or 1) == 1 then return spring end
    local dilated = {}
    for i, step in ipairs(spring or {}) do
        dilated[i] = { t = (step.t or 0)*dilation, x = step.x, y = step.y, ease = step.ease }
    end
    return dilated
end

---helper: _spring_mini_page_T
local function _spring_mini_page_T(gm, widget) _spring_draw_offset(gm, widget, "_save_menu_mini_page_enter", _mini_page_from, _dilated_spring(_mini_page_spring, _mini_page_dilation), _mini_at(_mini_start), _queue) end
local function _spring_draw_tree(gm, node, key, from, spring, delay) _spring_draw_offset(gm, node, key, from, spring, delay, _queue); for _, child in ipairs((node and node.children) or {}) do _spring_draw_tree(gm, child, key, from, spring, delay) end end
local function _fade_hint_children(gm, node, delay) for _, child in ipairs((node and node.children) or {}) do if child.config and child.config.renderer == "hint_btn" then ChildFadeTree.set_tree_alpha(child, 0); _after(gm, delay, function() if child.REMOVED then return true end; ChildFadeTree.fade_tree_in(child, gm, 0.72); return true end) end end end

---helper: fade_in
function M.fade_in(gm, mini)
    if not mini then return end

    _spring_mini_page_T(gm, mini)

    for i, child in ipairs(mini.page_child_widgets or {}) do local at = _mini_at(_mini_item_start + (i - 1)*_mini_item_stagger); _spring_draw_tree(gm, child, "_save_menu_mini_child_enter", _mini_item_from, _dilated_spring(_mini_item_spring, _mini_item_dilation), at); _fade_hint_children(gm, child, at) end
    for i, fx   in ipairs(mini.page_card_textfx or {})    do _spring_draw_offset(gm, fx, "_save_menu_mini_textfx_enter", _mini_item_from, _dilated_spring(_mini_item_spring, _mini_item_dilation), _mini_at(_mini_item_start + (#(mini.page_child_widgets or {}) + i - 1)*_mini_item_stagger), _queue) end
end

return M
