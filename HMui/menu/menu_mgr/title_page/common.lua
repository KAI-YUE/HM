local HMPanel  = require("HMEng.ui_actors.hm_panel")
local TabUtils = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

-----------------------------------------
--- title_page_room_T
-----------------------------------------
function M.title_page_room_T(gm) local RT = gm._room.T; return { x = RT.x, y = RT.y, w = RT.w, h = RT.h } end

-----------------------------------------
--- title_page_save_path
-----------------------------------------
function M.title_page_save_path(gm)
    local gp = gm.SET and gm.SET.profile
    if gm.slot_save_path then return gm:slot_save_path(gp) end
    return gp .. "/save.hm"
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
function M.title_page_panel_widget(panel, id)  if not panel then return end; return M.title_page_find_widget(panel.widget, id) or M.title_page_find_widget(panel.attached_panel, id) end
function M.title_page_snap_to(gm, id)          local node = M.title_page_panel_widget(gm.title_page_UI, id); if node and gm.CTRL then gm.CTRL:snap_to({ node = node }) end end
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
