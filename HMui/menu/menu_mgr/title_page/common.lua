local HMPanel  = require("HMEng.ui_actors.hm_panel")
local TabUtils = require("HMfns.utils.table_utils")
local CursorCommon = require("HMEng.controller.hid.mouse.cursor.common")

local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

-----------------------------------------
--- title_page_room_T
-----------------------------------------
function M.title_page_room_T(gm) local RT = gm._room.T; return { x = RT.x, y = RT.y, w = RT.w, h = RT.h } end

-----------------------------------------
--- title page save
-----------------------------------------
--- Helper: title_page_continue_slot_idx
local function title_page_continue_slot_idx(gm)
    local SET = gm.SET or {};                         if not gm.list_save_slot_summaries then return SET.slot_idx end
    local latest_i, latest_t
    for i, meta in ipairs(gm:list_save_slot_summaries()) do
        local saved_at = not meta.empty and tonumber(meta.saved_at)
        if saved_at and (not latest_t or saved_at > latest_t) then latest_i, latest_t = i, saved_at end
    end
    return latest_i or SET.slot_idx
end

--- Helper: title_page_save_path
function M.title_page_save_path(gm)
    local SET = gm.SET or {}
    local slot_idx = title_page_continue_slot_idx(gm)
    if gm.slot_save_path then return gm:slot_save_path(slot_idx), slot_idx end
    return (SET.profile or 1) .. "/save.hm"
end

-------------------------------------------
--- title_page_find_widget
-------------------------------------------
function M.title_page_find_widget(node, id)
    if not node then return end
    local cfg = node.config;                                  if cfg and (cfg.id == id or cfg.key == id) then return node end
    for _, child in ipairs(node.children or {})           do  local found = M.title_page_find_widget(child, id); if found then return found end; end
    for _, child in ipairs(node.page_child_widgets or {}) do  local found = M.title_page_find_widget(child, id); if found then return found end; end 
    for _, fx    in ipairs(node.page_card_textfx or {})   do  local found = M.title_page_find_widget(fx, id);    if found then return found end; end
end

-------------------------------------------------------------------------------------------
--- title_page_panel_widget | title_page_page_copy | title_page_snap_to
--------------------------------------------------------------------------------------------
--- Helper: title_page_clear_focus_hover
function M.title_page_clear_focus_hover(gm)
    local Ctrl = gm and gm.CTRL
    for _, key in ipairs({ "focused", "hovering", "cursor_hover" }) do
        local state = Ctrl and Ctrl[key]
        if state then CursorCommon.clear_child_focus_hover(state.target); state.target, state.prev_target = nil, nil end
    end
end

function M.title_page_panel_widget(panel, id)  if not panel then return end; return M.title_page_find_widget(panel.widget, id) or M.title_page_find_widget(panel.attached_panel, id) end
function M.title_page_snap_to(gm, id)          local node = M.title_page_panel_widget(gm.title_page_UI, id); if node and gm.CTRL then M.title_page_clear_focus_hover(gm); gm.CTRL:snap_to({ node = node }) end end
function M.title_page_page_copy(page_data, gm) return copy(type(page_data) == "function" and page_data(gm) or page_data) end

-------------------------------------------------
--- title_page_panel_args
-------------------------------------------------
function M.title_page_panel_args(gm, page)
    page.T,        page.fit_axis                     = M.title_page_room_T(gm), page.fit_axis or "width"
    page.type,     page.can_collide, page.can_hover  = "title_page", Y, Y
    page.hit_area, page.can_click,   page.can_drag   = "world", N, N
    return page
end

--------------------------------------------------
--- title_page_wipe_panel_args
--------------------------------------------------
function M.title_page_wipe_panel_args(gm, page)
    page = M.title_page_panel_args(gm, page)
    page.fx_mask_shader, page.fx_mask_ref = "_-1_page_wipe", "room"
    return page
end

-------------------------------------------------
--- title_page_switch_page
-------------------------------------------------
function M.title_page_switch_page(gm, page, focus_id, opts)
    local panel = gm.title_page_UI
    if not panel then return end 
    opts = opts or {}
    local delay = opts.delay or 0.55
    local renderer = panel.widget and panel.widget.config and panel.widget.config.renderer
    local switched
    if renderer == "art_page" and panel.switch_art_page then
        switched = panel:switch_art_page(page, { delay = delay, child_control_lock_delay = opts.child_control_lock_delay })
    elseif panel.switch_stroked_page then
        switched = panel:switch_stroked_page(page, { delay = delay, child_control_lock_delay = opts.child_control_lock_delay })
    end
    if switched and focus_id then gm.E_MANAGER:enqueue_event({ trigger = "after", delay = opts.focus_delay or delay + 0.05, blockable = N, func = function() M.title_page_snap_to(gm, focus_id); return Y end }) end
end

-------------------------------------------------
--- title_page_replace_panel
-------------------------------------------------
function M.title_page_replace_panel(gm, page, wipe)
    local old = gm.title_page_UI;           if old then old:remove() end
    gm.title_page_UI = HMPanel(gm, wipe and M.title_page_wipe_panel_args(gm, page) or M.title_page_panel_args(gm, page))
    gm.UI.title_page_panel = gm.title_page_UI
    return gm.title_page_UI
end

return M
