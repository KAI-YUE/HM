local TabUtils = require("HMfns.utils.table_utils")
local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")
local FadeTree = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")
local Construct = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.construct")
local Control = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.control")

local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

-----------------------------
--- switch stroked_page child widgets: fade old children out and new children in.
----------------------------------
--- Helper: remove_from_children | _switch_live
local function _remove_from_children(parent, child) for i = #parent.children, 1, -1 do if parent.children[i] == child then table.remove(parent.children, i); end; end; end
local function _switch_live(panel, token) return not panel or panel.stroked_page_switch_token == token; end

--- Helper: mark_tree_fading_out
local function _mark_tree_fading_out(widget, token)
    if not widget then return end
    widget.page_switch_fading_out = token or Y
    for _, child in ipairs(widget.children or {}) do _mark_tree_fading_out(child, token); end
end

--- Helper: clear_tree_fading_out
local function _clear_tree_fading_out(widget)
    if not widget then return end
    widget.page_switch_fading_out = nil
    for _, child in ipairs(widget.children or {}) do _clear_tree_fading_out(child); end
end

--- Helper: child_switch_live
local function _child_switch_live(panel, token, child) return _switch_live(panel, token) and child and not child.REMOVED and not child.page_switch_fading_out; end

--- Helper: finish
local function _finish(panel, widget, old_list, new_list, token, keep_control_locked)
    if panel.stroked_page_switch_token ~= token then return Y end
    for _, child in ipairs(old_list or {}) do
        _remove_from_children(widget, child)
        child:remove()
    end
    if not keep_control_locked then
        Common.hover_unlock_list(new_list, token)
        Common.disable_list(new_list, N)
    end
    if widget then widget.page_child_widgets = new_list end
    return Y
end

--- Helper: unlock_new_list
local function _unlock_new_list(panel, new_list, token)
    if panel.stroked_page_switch_token ~= token then return Y end
    Common.hover_unlock_list(new_list, token)
    Common.disable_list(new_list, N)
    return Y
end

--- Helper: visible_scrollable_items
local function _visible_scrollable_items(widget)
    local items, out = widget.scrollable_page_items or {}, {}
    for _, item in ipairs(items) do if item.states and item.states.visible then out[#out + 1] = item; end; end
    return out
end

--- Helper: restore_scrollable_items
local function _restore_scrollable_items(widget, panel, token)
    if not _switch_live(panel, token) then return Y end
    for _, item in ipairs(widget.scrollable_page_items or {}) do if _child_switch_live(panel, token, item) then FadeTree.fade_tree_in(item, nil, 0); end; end
    return Y
end

--- Helper: fade_scrollable_children_in
local function _fade_scrollable_children_in(widget, gm, delay, panel, token)
    local cfg     = widget.config or {}
    local start   = cfg.page_switch_enter_start or 0.25
    local stagger = cfg.page_switch_enter_stagger or 0.18
    local fade    = cfg.page_switch_enter_time or math.max(0.18, delay * 0.35)
    local items   = _visible_scrollable_items(widget)

    for _, item in ipairs(items) do FadeTree.set_tree_alpha(item, 0); end
    for i, item in ipairs(items) do
        Common.after(gm, start + stagger * (i - 1), function()
            if not _child_switch_live(panel, token, item) then return Y end
            FadeTree.fade_tree_in(item, gm, fade)
            return Y
        end)
    end
    Common.after(gm, start + stagger * #items + fade + 0.02, function() return _restore_scrollable_items(widget, panel, token); end)
end

--- Helper: fade_child_in
local function _fade_child_in(child, gm, delay, panel, token)
    if not _child_switch_live(panel, token, child) then return end

    local _cfg = child.config

    if _cfg.page_switch_manual_enter then return end
    if _cfg.page_switch_stagger_children and child.scrollable_page_items then return _fade_scrollable_children_in(child, gm, delay, panel, token); end

    local start = _cfg.page_switch_enter_start
    if start and start > 0 then
        return Common.after(gm, start, function()
            if not _child_switch_live(panel, token, child) then return Y end
            FadeTree.fade_tree_in(child, gm, child.config.page_switch_enter_time or delay)
            return Y
        end)
    end

    return FadeTree.fade_tree_in(child, gm, _cfg.page_switch_enter_time or delay)
end

function M.start(panel, widget, gm, child_cfg, delay, token)
    local old_list = widget.page_child_widgets or {}
    Common.hover_lock_list(old_list, token)
    Common.disable_list(old_list, Y)

    for _, child in ipairs(old_list) do
        _mark_tree_fading_out(child, token)
        FadeTree.fade_tree_to(child, gm, 0, delay)
    end

    widget.config.child_widgets = copy(child_cfg)
    local new_list = Construct.new_list(widget, gm, child_cfg)

    Common.hover_lock_list(new_list, token)
    Common.disable_list(new_list, Y)

    for _, child in ipairs(new_list) do _clear_tree_fading_out(child); end

    for _, child in ipairs(new_list) do
        local _cfg = child.config
        if     _cfg.page_switch_manual_enter then goto continue
        elseif _cfg.page_switch_stagger_children and child.scrollable_page_items then  _fade_child_in(child, gm, delay, panel, token)
        else   FadeTree.set_tree_alpha(child, 0); _fade_child_in(child, gm, delay, panel, token); end
        ::continue::
    end

    local draw_list = {}
    Common.append_list(draw_list, old_list)
    Common.append_list(draw_list, new_list)
    widget.page_child_widgets = draw_list

    return old_list, new_list
end

function M.queue_finish(panel, gm, widget, old_list, new_list, token, delay, control_lock_delay)
    if control_lock_delay then
        Control.lock(gm, token)
        Common.queue_after(gm, control_lock_delay, function() Control.unlock(gm, token); return _unlock_new_list(panel, new_list, token); end)
    else
        Control.unlock(gm)
    end
    Common.queue_after(gm, delay, function() return _finish(panel, widget, old_list, new_list, token, control_lock_delay ~= nil); end)
end

function M.replace_now(panel, widget, gm, child_cfg, token)
    if not widget then return end

    local old_list      = widget.page_child_widgets or {}
    local switch_token  = token or (panel and panel.stroked_page_switch_token) or 0

    widget.config.child_widgets = copy(child_cfg)

    local new_list = Construct.new_list(widget, gm, child_cfg)
    Common.disable_list(new_list, N)

    if panel then panel.stroked_page_switch_token = switch_token end
    return _finish(panel or { stroked_page_switch_token = switch_token }, widget, old_list, new_list, switch_token)
end

return M
