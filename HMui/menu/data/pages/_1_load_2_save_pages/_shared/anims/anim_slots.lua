local AnimUtils = require("HMfns.animate.transitions.anim_utils")

local floor = math.floor

local Y = true

local M = {}

local _slot_fade_time          = 0.72
local _slot_stagger            = 0.3
local _slot_start              = 0.92
local _slot_enter_paint_shader = "_1_watercolor_edge"
local _slot_enter_text_shader  = "_-2_stroke_wipe"
local _queue                   = "save_menu_enter"

--- Helper: _after | _ease 
local function _after(gm, delay, fn)                return AnimUtils.after(gm, delay, fn, _queue) end
local function _ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _queue) end

M.enter_text_shader = _slot_enter_text_shader
M.fade_time = _slot_fade_time

--- Helper: _slot_switch_live
local function _slot_switch_live(slot) return slot and not slot.REMOVED and not slot.page_switch_fading_out end

--- Helper: _slot_textfx_configs
local function _slot_textfx_configs(slot)
    local cfg, out = slot and slot.config, {}
    if cfg and cfg.textfx then out[#out + 1] = cfg.textfx end
    for _, textfx in ipairs((cfg and cfg.extra_textfx) or {}) do out[#out + 1] = textfx end
    for _, fx in ipairs((slot and slot.paint_rect_textfxs) or {}) do if fx.config then out[#out + 1] = fx.config end end
    return out
end

--- Helper: _slot_textfxs
local function _slot_textfxs(slot)
    local seen, out = {}, {}
    local function add(fx)
        if not fx or seen[fx] then return end
        seen[fx] = Y
        out[#out + 1] = fx
    end
    add(slot and slot.paint_rect_textfx)
    for _, fx in ipairs((slot and slot.paint_rect_textfxs) or {}) do add(fx) end
    return out
end

--- Helper: _slot_textfx_bg_configs
local function _slot_textfx_bg_configs(slot)
    local out = {}
    for _, cfg in ipairs(_slot_textfx_configs(slot)) do if type(cfg.text_bg) == "table" and cfg.text_bg.shader and cfg.text_bg.slot_enter_shader then out[#out + 1] = cfg.text_bg end end
    return out
end

--- Helper: _slot_child_widgets
local function _slot_child_widgets(slot)
    local out = {}
    local function visit(child)
        if not child then return end
        out[#out + 1] = child
        for _, sub in ipairs(child.children or {}) do visit(sub) end
    end
    for _, child in ipairs((slot and slot.children) or {}) do visit(child) end
    return out
end

--- Helper: _slot_child_shader_configs
local function _slot_child_shader_configs(slot)
    local out = {}
    for _, child in ipairs(_slot_child_widgets(slot)) do
        local cfg = child and child.config
        if cfg and cfg.slot_enter_shader and cfg.paint then out[#out + 1] = cfg end
    end
    return out
end

--- Helper: _cache_slot_shaders
local function _cache_slot_shaders(slot)
    local cfg = slot and slot.config;             if not cfg then return end
    if slot._save_menu_normal_shaders then return end

    local paint_cfg = cfg.paint or {}
    local textfx_shaders = {}
    for i, textfx in ipairs(_slot_textfx_configs(slot)) do textfx_shaders[i] = textfx.fx_mask_shader end
    local textfx_bg_shaders = {}
    for i, bg in ipairs(_slot_textfx_bg_configs(slot)) do textfx_bg_shaders[i] = bg.shader end
    local child_shaders = {}
    for i, child_cfg in ipairs(_slot_child_shader_configs(slot)) do child_shaders[i] = child_cfg.paint.shader end
    slot._save_menu_normal_shaders = {
        paint_shader  = paint_cfg.shader,
        text_shader   = cfg.text_mask_shader,
        textfx_shaders = textfx_shaders,
        textfx_bg_shaders = textfx_bg_shaders,
        child_shaders = child_shaders,
    }
end

--- Helper: _set_slot_enter_shaders
local function _set_slot_enter_shaders(slot)
    local cfg = slot and slot.config;             if not cfg then return end
    _cache_slot_shaders(slot)

    cfg.paint = cfg.paint or {}
    cfg.paint.shader = _slot_enter_paint_shader
    cfg.text_mask_shader = _slot_enter_text_shader

    for _, textfx in ipairs(_slot_textfx_configs(slot)) do textfx.fx_mask_shader = _slot_enter_text_shader end
    for _, bg in ipairs(_slot_textfx_bg_configs(slot)) do bg.shader = bg.slot_enter_shader end
    for _, child_cfg in ipairs(_slot_child_shader_configs(slot)) do child_cfg.paint.shader = child_cfg.slot_enter_shader end
end

--- Helper: _normal_draw_alpha
local function _normal_draw_alpha(widget) return widget and (widget.page_switch_draw_alpha or widget.draw_alpha) end

--- Helper: _cache_slot_draw_alpha
local function _cache_slot_draw_alpha(slot)
    if not slot or slot._save_menu_draw_alpha_cached then return end
    slot._save_menu_normal_draw_alpha = _normal_draw_alpha(slot)
    for _, child in ipairs(_slot_child_widgets(slot)) do
        child._save_menu_normal_draw_alpha = _normal_draw_alpha(child)
        child._save_menu_normal_fx_mask, child._save_menu_normal_fx_mask_dir = child.fx_mask, child.fx_mask_dir
    end
    slot._save_menu_draw_alpha_cached = Y
end

--- Helper: _set_slot_enter_draw_alpha
local function _set_slot_enter_draw_alpha(slot)
    if not slot then return end
    _cache_slot_draw_alpha(slot)
    slot.draw_alpha = 0
    for _, child in ipairs(_slot_child_widgets(slot)) do
        local cfg = child.config
        child.draw_alpha = 0
        if cfg and cfg.slot_enter_shader and cfg.paint then child.fx_mask, child.fx_mask_dir = 1, 1 end
    end
end

--- Helper: _fade_slot_child_in
local function _fade_slot_child_in(gm, slot, child, fade_time)
    if not _slot_switch_live(slot) or child.REMOVED or child.page_switch_fading_out then return Y end
    _ease(gm, child, "draw_alpha", child._save_menu_normal_draw_alpha or 1, fade_time, "lerp")
    if child.config and child.config.slot_enter_shader and child.config.paint then return _ease(gm, child, "fx_mask", 0, fade_time, "lerp") end
    return Y
end

--- Helper: _fade_slot_draw_alpha_in
local function _fade_slot_draw_alpha_in(gm, slot)
    if not _slot_switch_live(slot) then return Y end
    _ease(gm, slot, "draw_alpha", slot._save_menu_normal_draw_alpha or 1, _slot_fade_time, "lerp")
    for _, child in ipairs(_slot_child_widgets(slot)) do
        local enter_delay = child.config and child.config.slot_enter_delay
        if enter_delay then _after(gm, enter_delay, function() return _fade_slot_child_in(gm, slot, child, _slot_fade_time * 0.55) end)
        else               _fade_slot_child_in(gm, slot, child, _slot_fade_time) end
    end
    return Y
end

--- Helper: _fade_slot_delayed_textfx_in
local function _fade_slot_delayed_textfx_in(gm, slot, delay)
    for _, fx in ipairs(_slot_textfxs(slot)) do
        local cfg = fx.config
        local enter_delay = cfg and cfg.slot_enter_delay
        if not enter_delay then goto continue end 
        cfg.slot_enter_alpha = 0
        _after(gm, delay + enter_delay, function() if not _slot_switch_live(slot) or fx.REMOVED then return Y end; return _ease(gm, cfg, "slot_enter_alpha", 1, _slot_fade_time * 0.55, "lerp") end)
        _after(gm, delay + enter_delay + _slot_fade_time * 0.55 + 0.02, function() if _slot_switch_live(slot) and cfg then cfg.slot_enter_alpha = nil end; return Y; end)
        ::continue::
    end
end

--- Helper: _restore_slot_shaders
local function _restore_slot_shaders(slot)
    local cfg, normal = slot and slot.config, slot and slot._save_menu_normal_shaders
    if not (cfg and normal) then return Y end

    cfg.paint = cfg.paint or {}
    cfg.paint.shader      = normal.paint_shader
    cfg.text_mask_shader  = normal.text_shader

    for i, textfx in ipairs(_slot_textfx_configs(slot)) do textfx.fx_mask_shader = normal.textfx_shaders and normal.textfx_shaders[i] end
    for i, bg in ipairs(_slot_textfx_bg_configs(slot))  do bg.shader = normal.textfx_bg_shaders and normal.textfx_bg_shaders[i] end
    for i, child_cfg in ipairs(_slot_child_shader_configs(slot)) do child_cfg.paint.shader = normal.child_shaders and normal.child_shaders[i] end
    slot._save_menu_normal_shaders = nil
    return Y
end

--- Helper: _restore_slot_draw_alpha
local function _restore_slot_draw_alpha(slot)
    if not _slot_switch_live(slot) then return Y end
    slot.draw_alpha = slot._save_menu_normal_draw_alpha
    slot._save_menu_normal_draw_alpha = nil
    for _, child in ipairs(_slot_child_widgets(slot)) do
        child.draw_alpha, child._save_menu_normal_draw_alpha = child._save_menu_normal_draw_alpha, nil
        child.fx_mask, child.fx_mask_dir = child._save_menu_normal_fx_mask, child._save_menu_normal_fx_mask_dir
        child._save_menu_normal_fx_mask, child._save_menu_normal_fx_mask_dir = nil, nil
    end
    slot._save_menu_draw_alpha_cached = nil
    return Y
end

--- Helper: _handover_slot_fx_mask
local function _handover_slot_fx_mask(slot)
    if not _slot_switch_live(slot) then return Y end
    slot.fx_mask, slot.fx_mask_dir = 0, 1
    for _, child in ipairs(_slot_child_widgets(slot)) do child.fx_mask, child.fx_mask_dir = slot.fx_mask, slot.fx_mask_dir end
    return Y
end

--- Helper: _slot_max_enter_delay
local function _slot_max_enter_delay(slot)
    local max_delay = 0
    for _, child in ipairs(_slot_child_widgets(slot)) do max_delay = math.max(max_delay, child.config and child.config.slot_enter_delay or 0) end
    for _, cfg in ipairs(_slot_textfx_configs(slot)) do max_delay = math.max(max_delay, cfg.slot_enter_delay or 0) end
    return max_delay
end

--- Helper: _slot_index
local function _slot_index(cfg, n, start, slot)
    local idx = start + slot - 1
    if cfg.loop then return ((idx - 1) % n) + 1 end
    return idx >= 1 and idx <= n and idx
end

--- Helper: _page_start
local function _page_start(cfg, n)
    if n <= 0 then return 1 end
    if cfg.loop then return ((floor(cfg.page_start or 1) - 1) % n) + 1 end
    return math.max(1, math.min(floor(cfg.page_start or 1), n))
end

--- Helper: _visible_count
local function _visible_count(cfg, n) return math.min(math.max(floor(cfg.visible_count or n or 1), 1), math.max(n, 1)) end

--- Helper: _visible_slot_items
local function _visible_slot_items(slot_list)
    local items, cfg, out = slot_list and slot_list.scrollable_page_items or {}, slot_list and slot_list.config or {}, {}
    local n, start = #items, _page_start(cfg, #items)
    for slot = 1, _visible_count(cfg, n) do
        local idx = _slot_index(cfg, n, start, slot)
        if idx and items[idx] then out[#out + 1] = { slot = items[idx], pos = slot } end
    end
    return out
end

--- Helper: _fade_in_slot
local function _fade_in_slot(gm, slot, delay)
    if not slot then return end
    _set_slot_enter_shaders(slot)
    _set_slot_enter_draw_alpha(slot)
    slot.fx_mask, slot.fx_mask_dir = 1, 1
    _after(gm, delay, function()
        if not _slot_switch_live(slot) then return Y end
        _fade_slot_draw_alpha_in(gm, slot)
        return _ease(gm, slot, "fx_mask", 0, _slot_fade_time, "lerp")
    end)
    _fade_slot_delayed_textfx_in(gm, slot, delay)
end

-------------------------------
--- fade_in_slot_items
-------------------------------
function M.fade_in_slot_items(gm, slot_list)
    local visible_items = _visible_slot_items(slot_list)
    local last_restore_delay = 0

    slot_list.save_menu_enter_lock = Y

    for _, item in ipairs(visible_items) do
        local slot = item.slot
        local delay = _slot_start + _slot_stagger*((item.pos or 1) - 1)
        local restore_delay = delay + _slot_max_enter_delay(slot) + _slot_fade_time + 0.3
        last_restore_delay = math.max(last_restore_delay, restore_delay)
        _fade_in_slot(gm, slot, delay)
        _after(gm, restore_delay, function()
            if not _slot_switch_live(slot) then return Y end
            _restore_slot_shaders(slot)
            _restore_slot_draw_alpha(slot)
            _handover_slot_fx_mask(slot)
            return Y
        end)
    end

    _after(gm, last_restore_delay, function()
        slot_list.save_menu_enter_lock = nil
        return Y
    end)
end

return M
