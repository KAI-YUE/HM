local C           = require("HMfns.animate.color.color_const")
local ScrollPages = require("HMEng.ui_actors.hm_widget.renderers.love_brew.scrollable_list.discrete_entry")
local Slot        = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.slot")
local Tree        = require("HMEng.ui_actors.common.tree")

local ctl  = C.UI.TEXT_LIGHT

local default_slot_count = 9
local Y, N = true, false

local M = {}

--- Helper: save_slot_summaries | save_slot_count
local function save_slot_summaries(gm) return gm:list_save_slot_summaries() end
local function save_slot_count(gm)     local SD = gm.SET.save_data or {}; return SD.slot_count or default_slot_count end

--- Helper: recent_slot_idx
local function recent_slot_idx(summaries, count)
    local recent_i, recent_t
    for i = 1, count do
        local t = summaries[i] and not summaries[i].empty and tonumber(summaries[i].saved_at)
        if t and (not recent_t or t > recent_t) then recent_i, recent_t = i, t end
    end
    return recent_i
end

--- Helper: make_save_slots
local function make_save_slots(gm, summaries, count, opts)
    local slots, opts = {}, opts or {}
    opts.gm = gm
    for i = 1, count do slots[i] = Slot.make_slot(i, summaries[i], opts) end
    return slots
end

--- Helper: page_save_slots
local function page_save_slots(dir, list_id) return function(_, arrow)
    local list = Tree.find_child_by_id(arrow and arrow.parent, list_id or "save_slot_list")
    if list and not list.save_menu_enter_lock then ScrollPages.page(list, dir, 1) end
    return Y
end end

--- Helper: sprite_in_page, for arrows 
local function sprite_in_page(id, quad_key, x, y, r, dir, list_id)
    return { style  = "sprite_in_page",         id           = id,   
        quad_key    = quad_key,                 hook_fn      = page_save_slots(dir, list_id),
        hover_zoom  = 1.12,                     hover_shake  = { x = 0.04, y = 0.025, r = 0.045, speed = 34, settle = 8 },
        page_switch_manual_enter = Y,
        T = { x = x, y = y, r = r, w = 0.8 },
    }
end

--- Helper: reset_slot_fx_mask
local function reset_slot_fx_mask(slot)
    if not slot then return end
    slot.fx_mask, slot.fx_mask_dir = 0, 1
    for _, child in ipairs(slot.children or {}) do reset_slot_fx_mask(child) end
end

--- Helper: reset_visible_slot_fx_masks
local function reset_visible_slot_fx_masks(list) for _, slot in ipairs((list and list.scrollable_items) or {}) do if slot.states and slot.states.visible then reset_slot_fx_mask(slot) end end end

--- Helper: drag_slide_bar
local function drag_slide_bar(list_id)
    return function(_, bar, progress)
        local list = Tree.find_child_by_id(bar and bar.parent, list_id or "save_slot_list")
        if list and ScrollPages.set_progress(list, progress) then reset_visible_slot_fx_masks(list) end
    end
end

local x1, y1, x2, y2 = 0.37, 3.35, 1.54, 5.70

--- Helper: slide_bar_sprite
local function slide_bar_sprite(id, list_id, count)
    return {
        --- basic settings
        style = "sprite_in_page",         T = { x = x1, y = y1, r = -0.4, w = 0.58 },
        id = id or "save_page_slide_bar",
        atlas_key = "ui_pack",            quad_key = "btn_mask",

        --- hit settings
        button = Y,                       can_click = Y,               
        can_hover = Y,                    can_drag = Y,
        can_collide = Y,                  hover_zoom = 1.12,
        hit_padding = { x = 0.25, y = 0.25 },
        slider_drag = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, start_x = x1, start_y = y1, lock_track = Y, steps = count and math.max(count - 1, 1), on_change = drag_slide_bar(list_id) },

        --- color settings
        shadow = Y,                       tint = ctl,                  sprite_color = ctl,
        page_switch_manual_enter = Y,

    }
end

---______________________________________________
--- main: return saving slots page structure
---______________________________________________
function M.child_widgets(gm, opts)
    opts = opts or {}
    local list_id, page_id                = opts.list_id or "save_slot_list", opts.page_id_prefix or "save_page"
    local prev_id, slide_bar_id, next_id  = page_id .. "_prev", page_id .. "_slide_bar", page_id .. "_next"
    local summaries, count                = save_slot_summaries(gm), save_slot_count(gm)
    return {
        {   --- basics
            style      = "scrollable_discrete_entry", id            = list_id,
            loop       = Y,                        T               = { x = 3.5, y = 0.3, w = 20, h = 14 },
            axis       = "vertical",               visible_count   = 4,
            page_step  = 4,                        page_start = recent_slot_idx(summaries, count) or 1,
            page_duration   = 0.46,

            --- item settings
            item_gap        = 2.2,                 slide_bar_track = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 },
            x_bias          = 0.9,                 child_widgets   = make_save_slots(gm, summaries, count, opts),
            slide_bar_id    = slide_bar_id,
        },
        sprite_in_page(prev_id, "arrow-1", 0,   2.3,  -0.4,   -1, list_id),
        slide_bar_sprite(slide_bar_id, list_id, count),
        sprite_in_page(next_id, "arrow-2", 1.7,  6,   -0.4,   1, list_id),
    }
end

return M
