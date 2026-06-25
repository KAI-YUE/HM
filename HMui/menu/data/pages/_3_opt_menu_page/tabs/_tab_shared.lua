local C           = require("HMfns.animate.color.color_const")
local ScrollPages = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_pages")
local Tree        = require("HMEng.ui_actors.common.tree")
local Controls    = require("HMEng.ui_actors.hm_panel.prototype.control_panel")

local CUI = C.UI
local ctl = CUI.TEXT_LIGHT

local Y, N = true, false

local M = {}

local _scrollable_x, _scrollable_y = 5.3, 2.6
local _item_gap = 1.45

----------------------------------------
--- control_row | control_rows 
----------------------------------------
function M.control_row(gm, entry, control_args)     local control = Controls[entry.control]; return control.make(control_args(gm, entry)) end
function M.control_rows(gm, entries, control_args)  local rows = {}; for i, entry in ipairs(entries) do rows[i] = M.control_row(gm, entry, control_args) end; return rows end

---------------------------------------
--- page_options
---------------------------------------
function M.page_options(dir, list_id)
    return function(_, arrow)
        local list = Tree.find_child_by_id(arrow and arrow.parent, list_id)
        if list then ScrollPages.page(list, dir, 1) end
        return Y
    end
end

-----------------------------------------
--- page_arrow
-----------------------------------------
function M.page_arrow(id, quad_key, x, y, r, dir, list_id, enter_start, enter_time)
    return {
        --- basic settings
        style = "sprite_in_page",                       T = { x = x, y = y, r = r, w = 0.72 },
        id = id,                                        quad_key = quad_key,

        --- hit settings
        hover_zoom = 1.12,                              hover_shake = { x = 0.04, y = 0.025, r = 0.045, speed = 34, settle = 8 },
        gamepad_focus = N,
        hook_fn = M.page_options(dir, list_id),

        --- animation
        page_switch_enter_start = enter_start,          page_switch_enter_time = enter_time,
    }
end

------------------------------------------
--- slide_bar
-----------------------------------------
function M.slide_bar(id, enter_start, enter_time)
    return {
        --- basic settings
        style     = "sprite_in_page",                   T = { x = 0.42, y = 3.15, r = -0.4, w = 0.52 },
        id        = id,                                 atlas_key = "ui_pack",
        quad_key  = "btn_mask",

        --- hit settings
        button    = N,                                  can_click = N,
        can_hover = N,                                  can_drag  = N,

        --- color settings
        shadow        = Y,                              tint = ctl,
        sprite_color  = ctl,

        --- animation settings
        page_switch_enter_start = enter_start,          page_switch_enter_time = enter_time,
    }
end

-------------------------------------
--- option_widgets
-------------------------------------
function M.option_widgets(gm, cfg)
    local list_id,      bar_id         = cfg.list_id,                        cfg.bar_id
    local enter_start,  enter_time     = cfg.enter_start or 1.8,             cfg.enter_time or 0.58
    local scrollable_x, scrollable_y   = cfg.scrollable_x or _scrollable_x,  cfg.scrollable_y or _scrollable_y
    local item_gap                     = cfg.item_gap or _item_gap
    local entries,      visible_count  = cfg.entries or {},                  cfg.visible_count or 6
    local defined_count                = #entries
    local widgets,      can_scroll     = {},                                 defined_count > visible_count

    widgets[#widgets + 1] = {  --- basic settings
        style  = "scrollable_pages",            T    = { x = scrollable_x, y = scrollable_y, w = 15, h = 14 }, 
        id     = list_id,                       loop = N,                               
        axis   = "vertical",                    visible_count = visible_count,

        --- scrollable_page settings
        page_start     = 1,                     page_step        = 3,
        page_duration  = 0.42,                  item_gap         = item_gap,
        x_bias         = 0.78,                  slide_bar_track  = { x1 = 0.42, y1 = 3.15, x2 = 1.2, y2 = 4.6 },
        slide_bar_id   = can_scroll and bar_id,
        child_widgets  = M.control_rows(gm, entries, cfg.control_args),

        --- animation settings
        page_switch_enter_start  = enter_start, page_switch_enter_stagger    = 0.22,
        page_switch_enter_time   = enter_time,  page_switch_stagger_children = Y,
    }

    if can_scroll then
        widgets[#widgets + 1] = M.page_arrow(cfg.prev_id, "arrow-1", 0.08, 2.55, -0.4, -1, list_id, enter_start, enter_time)
        widgets[#widgets + 1] = M.slide_bar(bar_id, enter_start, enter_time)
        widgets[#widgets + 1] = M.page_arrow(cfg.next_id, "arrow-2", 1.48, 5.15, -0.4, 1, list_id, enter_start, enter_time)
    end

    return widgets
end

return M
