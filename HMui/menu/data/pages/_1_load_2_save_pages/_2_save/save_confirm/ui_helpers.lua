local ConfirmPopup   = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")
local TabDef         = require("HMui.menu.data.pages._1_load_2_save_pages._shared.confirm_tab_def")
local Tree           = require("HMEng.ui_actors.common.tree")
local Anims          = require("HMfns.animate.transitions.anim_utils")
local SlotText       = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.text")
local SpriteRenderer = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite")
local SlotRefresh    = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.refresh")

local find_child_by_id  = Tree.find_child_by_id

local _queue = "save_menu_enter"
local _refresh_time         = 1.2
local _refresh_brightness   = 0.38

local Y, N = true, false

local M = {}

local default_icon = { atlas_key = "icons", quad_key = "question_mark" }
local popup_args = {
    text_box_T      = { x = 0, y = 0.45, w = 8.1, h = 3.35 },
    -- text_offset     = { x = 0, y = 1 },
    ui_key          = "save_slot_confirm",
    slot_key        = "save_slot_confirm_slot_idx",
    queue           = "save_slot_confirm",
    id_prefix       = "save_slot_confirm",
    prompt_key      = "save_data_here",
    prompt_fallback = "Save data here?",
    yes_hook_fn     = "confirm_save_slot_yes",
    no_hook_fn      = "confirm_save_slot_no",
}

---------------------------------
--- remove_popup
---------------------------------
function M.remove_popup(gm) ConfirmPopup.remove_popup(gm, popup_args) end

--------------------------------
---  show_popup
--------------------------------
function M.show_popup(gm, slot_idx)
    popup_args.slot_idx = slot_idx
    popup_args.title_widget = TabDef.title_widget(slot_idx)
    ConfirmPopup.show_popup(gm, popup_args)
end

---------------------------------------------------
--- refresh_save_slot_ui
---------------------------------------------------
--- Helper: current_save_slot_list
local function current_save_slot_list(gm)
    local OM = gm and gm.UI and gm.UI.overlay_menu;     if not OM then return end
    return (OM.get_UI_by_ID and OM:get_UI_by_ID("save_slot_list")) or find_child_by_id(OM.UIRoot or OM.widget, "save_slot_list")
end

--- Helper: clear_slot_text_cache
local function clear_slot_text_cache(slot)
    local cfg = slot and slot.config;                   if not cfg then return end

    cfg.text_drawable,  cfg.text_drawable_runs                     = nil, nil
    cfg.prev_text,      cfg.prev_raw_text,         cfg.prev_value  = nil, nil, nil
    cfg.text_parse,     cfg.text_parse_cache_key,  cfg.text_pages  = nil, nil, nil
    cfg.text_page,      cfg.text_reveal_source                     = 1, nil
    if slot.paint_rect_textfx and slot.paint_rect_textfx.config then slot.paint_rect_textfx.config.card_textfx_cache = nil end
    for _, fx in ipairs(slot.paint_rect_textfxs or {}) do if fx.config then fx.config.card_textfx_cache = nil end end
end

--- Helper: apply_slot_playtime_textfx
local function apply_slot_playtime_textfx(slot, meta)
    local cfg = slot and slot.config
    local textfx = cfg and cfg.extra_textfx and cfg.extra_textfx[1];        if not textfx then return end
    textfx.text = SlotText.playtime_text(meta)
    local fx = slot.paint_rect_textfxs and slot.paint_rect_textfxs[2];      if fx and fx.config then fx.config.text, fx.config.card_textfx_cache = textfx.text, nil end
end

--- Helper: safe_slot_icon_cfg
local function safe_slot_icon_cfg(gm, meta)
    local icon_cfg = type(meta) == "table" and type(meta.icon) == "table" and meta.icon or default_icon
    local atlas_key, quad_key = icon_cfg.atlas_key or default_icon.atlas_key, icon_cfg.quad_key or default_icon.quad_key
    local atlas = gm and gm.T_atlas and gm.T_atlas[atlas_key]
    if atlas and atlas.quads and atlas.quads[quad_key] then return atlas_key, quad_key end
    return default_icon.atlas_key, default_icon.quad_key
end

--- Helper: apply_slot_icon
local function apply_slot_icon(gm, slot, meta)
    local icon = find_child_by_id(slot, "save_slot_profile_icon");             if not icon then return end
    icon.config.atlas_key, icon.config.quad_key = safe_slot_icon_cfg(gm, meta)
    SpriteRenderer.init(icon, gm)
end

--- Helper: apply_slot_summary
local function apply_slot_summary(gm, slot, meta)
    local cfg = slot and slot.config;        if not cfg then return end
    cfg.save_slot_meta  = meta
    cfg.text            = SlotText.summary_text(meta)
    apply_slot_playtime_textfx(slot, meta)
    apply_slot_icon(gm, slot, meta)
    clear_slot_text_cache(slot)
    if slot.update_text then slot:update_text() end
end

--- Helper: gate_slot_hover
local function gate_slot_hover(slot)
    local hover = slot and slot.states and slot.states.hover;     if not hover then return end
    if slot._save_menu_refresh_hover_can == nil then slot._save_menu_refresh_hover_can = hover.can end
    hover.can, hover.is = N, N
end

--- Helper: restore_slot_hover
local function restore_slot_hover(slot)
    local hover = slot and slot.states and slot.states.hover;     if not hover then return end
    if slot._save_menu_refresh_hover_can ~= nil then hover.can = slot._save_menu_refresh_hover_can end
    slot._save_menu_refresh_hover_can = nil
end

--- Helper: each_slot_textfx
local function each_slot_textfx(slot, fn)
    local seen = {}
    local function visit(fx) if not fx or seen[fx] then return end; seen[fx] = Y; fn(fx) end
    visit(slot and slot.paint_rect_textfx)
    for _, fx in ipairs((slot and slot.paint_rect_textfxs) or {}) do visit(fx) end
end

--- Helper: clear_slot_light_sweep
local function clear_slot_light_sweep(slot, token)
    if not slot or slot._save_menu_refresh_token ~= token then return Y end
    restore_slot_hover(slot)
    slot.light_sweep, slot.light_sweep_brightness, slot._save_menu_refresh_token = nil, nil, nil
    each_slot_textfx(slot, function(fx) fx.light_sweep, fx.light_sweep_brightness = nil, nil end)
    return Y
end

--- Helper: hint_slot_refreshed
local function hint_slot_refreshed(gm, slot)
    if not slot then return end
    local token = {}
    slot._save_menu_refresh_token = token
    gate_slot_hover(slot)

    slot.light_sweep = 0
    slot.light_sweep_brightness = _refresh_brightness
    Anims.ease(gm, slot, "light_sweep", 1, _refresh_time, "lerp", _queue)
    each_slot_textfx(slot, function(fx)
        fx.light_sweep = 0
        fx.light_sweep_brightness = _refresh_brightness
        Anims.ease(gm, fx, "light_sweep", 1, _refresh_time, "lerp", _queue)
    end)

    Anims.after(gm, _refresh_time + 0.02, function() return clear_slot_light_sweep(slot, token) end, _queue)
end

---_________________________________
--- main: refresh_save_slot_ui
---_________________________________
function M.refresh_save_slot_ui(gm, slot_idx, saved_data)
    local meta       = (saved_data and saved_data.meta) or (gm.save_slot_summary and gm:save_slot_summary(slot_idx))
    SlotRefresh.refresh(gm, slot_idx, meta)
end

return M
