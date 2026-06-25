local C, CUtils       = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local ChildAnimations = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets")
local OptMenuData     = require("HMui.menu.data.pages._3_opt_menu_page")
local SnapshotTrans   = require("HMui.menu.transitions.snapshot")
local SeedLists       = require("HMui.menu.transitions.seed_lists")
local TabUtils        = require("HMfns.utils.table_utils")
local Common          = require("HMui.menu.menu_mgr.title_page.common")

local copy, random_pick = TabUtils.deep_copy, TabUtils.random_pick

local Y, N = true, false

local M = {}

local title_page_options_wipe_time = 1.2
local title_page_options_underlay_dim = CUtils.tint_with_alpha(C.STEEL, 0.4)

-------------------------------------------------
--- title_page_options_page
-------------------------------------------------
function M.title_page_options_page(gm)
    local page = copy(OptMenuData(gm, { region_polygons = "title" }))
    if page.card_textfx and page.card_textfx[1] then page.card_textfx[1].hook_fn = "title_page_options_back" end
    return page
end

-------------------------------------------------
--- lock_title_page_options_ctrl
-------------------------------------------------
function M.lock_title_page_options_ctrl(gm)
    local Ctrl = gm and gm.CTRL;                       if not Ctrl then return end
    local locks = Ctrl.locks
    locks.frame_set, locks.frame, locks.title_page_options = Y, Y, Y
    if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end
end

-------------------------------------------------
--- unlock_title_page_options_ctrl
-------------------------------------------------
function M.unlock_title_page_options_ctrl(gm)
    local Ctrl = gm and gm.CTRL;                       if not Ctrl then return Y end
    Ctrl.locks.title_page_options = nil
    return Y
end

-------------------------------------------------
--- clear_title_page_options_transition_ctrl
-------------------------------------------------
function M.clear_title_page_options_transition_ctrl(gm)
    local Ctrl = gm and gm.CTRL;                       if not (Ctrl and Ctrl.locks) then return Y end
    Ctrl.locks.title_page_options = nil
    Ctrl.locks.stroked_page_child_control = nil
    return Y
end

-------------------------------------------------
---  title_page_options_wipe_seed
-------------------------------------------------
function M.title_page_options_wipe_seed() return random_pick(SeedLists.options2pause_page_wipe) end

-------------------------------------------------
--- title_page_wipe_in_panel
-------------------------------------------------
function M.title_page_wipe_in_panel(gm, panel, delay)
    local widget = panel and panel.widget;                   if not widget then return end
    widget.fx_mask, widget.fx_mask_seed = 1, M.title_page_options_wipe_seed()
    gm.E_MANAGER:enqueue_event({ trigger = "ease", ease = "lerp", blockable = N, ref_table = widget, ref_value = "fx_mask", ease_to = 0, delay = delay })
end

---------------------------------------------------
--- title_page_options_enter
---------------------------------------------------
function M.title_page_options_enter(gm, panel, page)
    local fn = page.switch_anim and page.switch_anim.enter
    if type(fn) == "function" then fn(gm, panel, page, { text_new = panel.widget and panel.widget.page_card_textfx or {} }) end
end

--------------------------------------------------
--- title_page_take_child_widgets
--------------------------------------------------
function M.title_page_take_child_widgets(page)
    local children, lock_delay = page.child_widgets, page.child_control_lock_delay
    page.child_widgets = nil
    return children, lock_delay
end

---------------------------------------------------
--- title_page_fade_in_children
---------------------------------------------------
function M.title_page_fade_in_children(gm, panel, children, delay, control_lock_delay)
    local widget  = panel and panel.widget;                    if not widget then return end
    local token   = (panel.stroked_page_switch_token or 0) + 1
    panel.stroked_page_switch_token = token
    panel.stroked_page_child_control_lock_delay = control_lock_delay
    local old_children, new_children = ChildAnimations.start(panel, widget, gm, children, delay, token)
    ChildAnimations.queue_finish(panel, gm, widget, old_children, new_children, token, delay, control_lock_delay)
    return new_children
end

-----------------------------------------------------
--- title_page_capture_options_snapshot
-----------------------------------------------------
function M.title_page_capture_options_snapshot(gm)
    gm.title_page_options_snapshot = SnapshotTrans.capture_canvas(gm)
    gm.title_page_options_snapshot_shader = "mc_polar"
    gm.title_page_options_snapshot_blur_radius = 5.
    gm.title_page_options_snapshot_dim_color = title_page_options_underlay_dim
    gm.title_page_options_snapshot_shader_time = gm._T and gm._T.real_s or 0
    return gm.title_page_options_snapshot
end

-----------------------------------------------------
--- title_page_options
-----------------------------------------------------
function M.title_page_options(gm)
    M.lock_title_page_options_ctrl(gm)
    M.title_page_capture_options_snapshot(gm)
    local page                         = M.title_page_options_page(gm)
    local children, control_lock_delay = M.title_page_take_child_widgets(page)
    local panel                        = Common.title_page_replace_panel(gm, page, Y)
    
    gm.UI.title_page_options = Y
    M.title_page_wipe_in_panel(gm, panel, title_page_options_wipe_time)
    M.title_page_fade_in_children(gm, panel, children, title_page_options_wipe_time, control_lock_delay)
    M.title_page_options_enter(gm, panel, page)

    gm.E_MANAGER:enqueue_event({ trigger = "after", delay = title_page_options_wipe_time, blockable = N, func = function()
        Common.title_page_snap_to(gm, "back")
        return M.unlock_title_page_options_ctrl(gm)
    end })
    return Y
end

return M
