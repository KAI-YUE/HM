local Tree           = require("HMEng.ui_actors.common.tree")
local Anims          = require("HMfns.animate.transitions.anim_utils")
local SlotText       = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.text")
local SpriteRenderer = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite")

local find_child_by_id = Tree.find_child_by_id

local _queue              = "save_menu_enter"
local _refresh_time       = 1.2
local _refresh_brightness = 0.38

local Y, N = true, false

local M = {}

local default_icon = { atlas_key = "icon_pack", quad_key = "question_mark" }

--------------------------------------------------
--- Helper: current slot widget
--------------------------------------------------
local function current_slot_widget(gm, slot_idx)
    local OM = gm and gm.UI and gm.UI.overlay_menu;          if not OM then return end
    local root = OM.UIRoot or OM.widget

    for _, prefix in ipairs({ "save_slot", "load_slot" }) do
        local slot = (OM.get_UI_by_ID and OM:get_UI_by_ID(("%s_%d"):format(prefix, slot_idx))) or find_child_by_id(root, ("%s_%d"):format(prefix, slot_idx))
        if slot then return slot end
    end
end

--------------------------------------------------
--- Helper: clear slot text cache
--------------------------------------------------
local function clear_slot_text_cache(slot)
    local cfg = slot and slot.config;                       if not cfg then return end

    cfg.text_drawable,  cfg.text_drawable_runs                     = nil, nil
    cfg.prev_text,      cfg.prev_raw_text,         cfg.prev_value  = nil, nil, nil
    cfg.text_parse,     cfg.text_parse_cache_key,  cfg.text_pages  = nil, nil, nil
    cfg.text_page,      cfg.text_reveal_source                     = 1, nil
    if slot.paint_rect_textfx and slot.paint_rect_textfx.config then slot.paint_rect_textfx.config.card_textfx_cache = nil end
    for _, fx in ipairs(slot.paint_rect_textfxs or {}) do if fx.config then fx.config.card_textfx_cache = nil end end
end

--------------------------------------------------
--- Helper: apply playtime textfx
--------------------------------------------------
local function apply_slot_playtime_textfx(slot, meta)
    local cfg = slot and slot.config
    local textfx = cfg and cfg.extra_textfx and cfg.extra_textfx[1];        if not textfx then return end
    textfx.text = SlotText.playtime_text(meta)
    local fx = slot.paint_rect_textfxs and slot.paint_rect_textfxs[2];      if fx and fx.config then fx.config.text, fx.config.card_textfx_cache = textfx.text, nil end
end

--------------------------------------------------
--- Helper: safe slot icon config
--------------------------------------------------
local function safe_slot_icon_cfg(gm, meta)
    local icon_cfg = type(meta) == "table" and type(meta.icon) == "table" and meta.icon or default_icon
    local atlas_key, quad_key = icon_cfg.atlas_key or default_icon.atlas_key, icon_cfg.quad_key or default_icon.quad_key
    local atlas = gm and gm.T_atlas and gm.T_atlas[atlas_key]
    if atlas and atlas.quads and atlas.quads[quad_key] then return atlas_key, quad_key end
    return default_icon.atlas_key, default_icon.quad_key
end

--------------------------------------------------
--- Helper: apply slot icon
--------------------------------------------------
local function apply_slot_icon(gm, slot, meta)
    local icon = find_child_by_id(slot, "save_slot_profile_icon");             if not icon then return end
    icon.config.atlas_key, icon.config.quad_key = safe_slot_icon_cfg(gm, meta)
    SpriteRenderer.init(icon, gm)
end

--------------------------------------------------
--- Helper: apply slot summary
--------------------------------------------------
local function apply_slot_summary(gm, slot, meta)
    local cfg = slot and slot.config;                   if not cfg then return end
    local has_data = type(meta) == "table" and not meta.empty
    local can_click = has_data or cfg.primary_on_empty == Y

    cfg.save_slot_meta      = meta
    cfg.can_click           = can_click
    cfg.secondary_action    = has_data and "delete" or nil
    cfg.secondary_hook_fn   = has_data and "delete_save_slot" or nil
    cfg.text                = SlotText.summary_text(meta)
    if slot.states and slot.states.click then slot.states.click.can = can_click end
    apply_slot_playtime_textfx(slot, meta)
    apply_slot_icon(gm, slot, meta)
    clear_slot_text_cache(slot)
    if slot.update_text then slot:update_text() end
end

--------------------------------------------------
--- Helper: gate slot hover
--------------------------------------------------
local function gate_slot_hover(slot)
    local hover = slot and slot.states and slot.states.hover;          if not hover then return end
    if slot._save_menu_refresh_hover_can == nil then slot._save_menu_refresh_hover_can = hover.can end
    hover.can, hover.is = N, N
end

--------------------------------------------------
--- Helper: restore slot hover
--------------------------------------------------
local function restore_slot_hover(slot)
    local hover = slot and slot.states and slot.states.hover;          if not hover then return end
    if slot._save_menu_refresh_hover_can ~= nil then hover.can = slot._save_menu_refresh_hover_can end
    slot._save_menu_refresh_hover_can = nil
end

--------------------------------------------------
--- Helper: each slot textfx
--------------------------------------------------
local function each_slot_textfx(slot, fn)
    local seen = {}
    local function visit(fx) if not fx or seen[fx] then return end; seen[fx] = Y; fn(fx) end
    visit(slot and slot.paint_rect_textfx)
    for _, fx in ipairs((slot and slot.paint_rect_textfxs) or {}) do visit(fx) end
end

--------------------------------------------------
--- Helper: clear slot light sweep
--------------------------------------------------
local function clear_slot_light_sweep(slot, token)
    if not slot or slot._save_menu_refresh_token ~= token then return Y end
    restore_slot_hover(slot)
    slot.light_sweep, slot.light_sweep_brightness, slot._save_menu_refresh_token = nil, nil, nil
    each_slot_textfx(slot, function(fx) fx.light_sweep, fx.light_sweep_brightness = nil, nil end)
    return Y
end

--------------------------------------------------
--- Helper: hint slot refreshed
--------------------------------------------------
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

--------------------------------------------------
--- Main: refresh slot UI
--------------------------------------------------
function M.refresh(gm, slot_idx, meta)
    slot_idx = tonumber(slot_idx) or 1
    local slot = current_slot_widget(gm, slot_idx);       if not slot then return end
    meta = meta or (gm.save_slot_summary and gm:save_slot_summary(slot_idx))
    apply_slot_summary(gm, slot, meta)
    hint_slot_refreshed(gm, slot)
end

return M
