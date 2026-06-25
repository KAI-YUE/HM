local TabUtils = require("HMfns.utils.table_utils")
local HMWidget = require("HMEng.ui_actors.hm_widget")
local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")
local FadeTree = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.attached_panel.fade_tree")

local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

-----------------------------
--- switch stroked_page attached panel: fade old mini-page out and new mini-page in.
----------------------------------
--- Helper: new_attached
local function _new_attached(gm, attached_panel) if attached_panel then return HMWidget(gm, copy(attached_panel)) end end

--- Helper: finish
local function _finish(panel, old_attached, new_attached, token)
    if panel.stroked_page_switch_token ~= token then return Y end
    if old_attached then old_attached:remove() end
    FadeTree.clear_textfx_switch_fade(new_attached)
    panel.switch_attached_panels = nil
    return Y
end

function M.start(panel, gm, attached_panel, delay)
    Common.remove_list(panel.switch_attached_panels)
    panel.switch_attached_panels = nil

    local old_attached = panel.attached_panel
    if old_attached then Common.disable_tree(old_attached, Y); FadeTree.fade_tree_to(gm, old_attached, 0, delay) end

    local new_attached = _new_attached(gm, attached_panel)
    panel.attached_panel = new_attached
    if old_attached then panel.switch_attached_panels = { old_attached } else panel.switch_attached_panels = nil end

    if new_attached then
        Common.disable_tree(new_attached, Y)
        FadeTree.set_tree_alpha(new_attached, 0)
        FadeTree.fade_tree_in(gm, new_attached, delay)
    end

    return old_attached, new_attached
end

function M.queue_finish(panel, gm, old_attached, new_attached, token, delay)
    Common.queue_after(gm, delay, function()
        if new_attached then Common.disable_tree(new_attached, N) end
        return _finish(panel, old_attached, new_attached, token)
    end)
end

return M
