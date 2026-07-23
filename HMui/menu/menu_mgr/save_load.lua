local HMPanel      = require("HMEng.ui_actors.hm_panel")
local TabUtils     = require("HMfns.utils.table_utils")
local LoadMenuData = require("HMui.menu.data.pages._1_load_2_save_pages._1_load")
local Transitions  = require("HMfns.animate.transitions.menu_transitions")

local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

-------------------------------------------------
--- Open load menu
-------------------------------------------------
--- Helper: _escape_split_T | page_data
local function _escape_split_T(gm) local RT = gm._room.T; return { x = RT.x, y = RT.y, w = RT.w, h = RT.h } end
local function page_data(page, gm) if type(page) == "function" then return page(gm) end; return page end

---____________________________________
--- main: open_load_menu
---____________________________________
function M.open_load_menu(gm)
    local gUI = gm.UI
    local OM, Ctrl = gUI.overlay_menu, gm.CTRL
    local replacing = (not not OM)
    if OM then OM:remove() end

    local Cl = Ctrl.locks
    Cl.frame_set, Cl.frame, Ctrl.cursor_down.target = Y, Y, nil
    Ctrl:mod_cursor_context_layer((gm.fix_cursor_stack or replacing) and 0 or 1)

    gm.SET.pause = Y
    local args = copy(page_data(LoadMenuData, gm))
    args.T,        args.fit_axis                        = _escape_split_T(gm), "width"
    args.type,     args.can_collide,  args.can_hover    = "overlay_menu", Y, Y
    args.hit_area, args.can_click,    args.can_drag     = "world",        N, N
    args.fx_mask_shader,              args.fx_mask_ref  = "_-1_page_wipe", "room"

    gUI.overlay_menu = HMPanel(gm, args)
    OM = gUI.overlay_menu
    OM.config = OM.config or {}
    OM.config.no_esc, OM.config.underlay = N, "snapshot"
    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end

    Transitions.open_pause_menu(gm, OM)
end

return M
