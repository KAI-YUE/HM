local Base     = require("HMEng.ui_actors.hm_widget.renderers.love_brew.btn_container")
local Metrics  = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.metrics")
local I18N     = require("HMfns.utils.format.i18n_utils")

local i18n     = I18N.i18n

local Y, N     = true, false

local M = {
    config_keys     = { "hid_action", "hid_button", "show_when", "show_when_parent", "hit_mask_box", "hint_atlas_key", "hint_mask_atlas_key", "hint_mask_quad_key", "hint_mask_suffix", "hint_mask_map", "hint_icon_quad_key", "hint_icon_quad_keys", "hint_icon_show_when", "hint_console", "hint_label_map", "hint_label_i18n_key", "hint_label_i18n_type", "hint_label_i18n_scope", "label_x_offset_by_lang", "options_tab_step", "click_visual_time", "widget_dist", "hover_tint", "shadow_parallax", "hint_enter_fade", "hint_enter_wipe", "parent_cut_in_sync", "parent_cut_in_delay", "parent_cut_in_time", "parent_cut_in_ease", "opt_tab_cut_in_sync" },
    hit_test        = Base.hit_test,
    draw            = Base.draw,
}

local FACE = {
    Playstation = { a = "cross", b = "circle", x = "square", y = "triangle", start = "ps_options" },
    Xbox        = { a = "A",     b = "B",      x = "x",      y = "Y",        start = "pad_option" },
    Generic     = { a = "A",     b = "B",      x = "x",      y = "Y",        start = "pad_option" },
    Nintendo    = { a = "A",     b = "B",      x = "x",      y = "Y",        start = "pad_option" },
    SteamDeck   = { a = "A",     b = "B",      x = "x",      y = "Y",        start = "pad_option" },
}

local BUTTON_QUADS = {
    dpup          = "dpad_1btn",  dpdown         = "dpad_1btn",    dpleft       = "dpad_1btn",       dpright       = "dpad_1btn",
    leftshoulder  = "lb_btn",     rightshoulder  = "rb_btn",       triggerleft  = "LT",              triggerright  = "LT",
    camup         = "dpad",       camdown        = "dpad",         camleft      = "dpad",            camright      = "dpad",
}

--- Helper: set hint tree visibility
local function set_visible(node, visible)
    if not node then return end
    if node.states then node.states.visible = visible end
    for _, child in ipairs(node.children or {}) do set_visible(child, visible) end
end

--- Helper: set hint tree wipe
local function set_wipe(node, value)
    if not node then return end
    node.fx_mask, node.fx_mask_dir = value, 1
    for _, child in ipairs(node.children or {}) do set_wipe(child, value) end
end

--- Helper: ease hint tree wipe
local function ease_wipe(self, node, token)
    if not node then return end
    local cfg, EM = self.config, self.gm and self.gm.E_MANAGER;       if not EM then return set_wipe(self, 0) end
    EM:enqueue_event({ trigger = "ease", ease = cfg.parent_cut_in_ease or "lerp", blockable = N, blocking = N,
        ref_table = node, ref_value = "fx_mask", ease_to = 0, delay = cfg.parent_cut_in_time or 0.18,
        func = function(v) return self._parent_cut_in_token == token and v or (node.fx_mask or 0) end,
    })
    for _, child in ipairs(node.children or {}) do ease_wipe(self, child, token) end
end

--- Helper: sync parent cut-in
local function sync_parent_cut_in(self, active)
    if not self.config.parent_cut_in_sync then return end
    if not active then
        if not self._parent_cut_in_active then return end
        self._parent_cut_in_active = N
        self._parent_cut_in_token = (self._parent_cut_in_token or 0) + 1
        return set_wipe(self, 1)
    end
    if self._parent_cut_in_active then return end

    self._parent_cut_in_active = Y
    self._parent_cut_in_token = (self._parent_cut_in_token or 0) + 1
    local token, delay = self._parent_cut_in_token, self.config.parent_cut_in_delay or 0.08
    set_wipe(self, 1)

    local EM = self.gm and self.gm.E_MANAGER
    if not EM or delay <= 0 then return ease_wipe(self, self, token) end
    EM:enqueue_event({ trigger = "after", delay = delay, blockable = N, blocking = N,
        func = function() if self._parent_cut_in_token == token then ease_wipe(self, self, token) end; return Y end,
    })
end

--- Helper: show_when visible
local function show_when_visible(Ctrl, mode)
    if not mode or mode == "always" then return Y end
    local HID = Ctrl and Ctrl.HID;                          if not HID then return Y end

    if mode == "controller" then if HID.input_mode == "keyboard" then return N end; return (HID.input_mode == "controller" or ((HID.input_mode == nil or HID.input_mode == "") and HID.controller == Y) or (HID.controller == Y and (HID.pointer == Y or HID.touch == Y))) or N end
    if mode == "keyboard"   then return HID.input_mode == "keyboard" or N end
    if mode == "pointer"    then return HID.pointer    == Y or N end
    if mode == "mouse"      then return HID.mouse      == Y or N end
    if mode == "touch"      then return HID.touch      == Y or N end
    return Y
end

--- Helper: parent state visible
local function parent_state_visible(self, mode)
    if not mode then return Y end
    local parent, cfg = self.parent, self.parent and self.parent.config
    if not (parent and parent.states and parent.states.visible) then return N end
    if mode == "selected" then return cfg and cfg.options_tab_visual_state == "selected" or N end
    local states = parent and parent.states
    local active = states and (((states.hover and states.hover.is) or (states.focus and states.focus.is)) and Y or N) or N
    local empty  = not (cfg and type(cfg.save_slot_meta) == "table" and not cfg.save_slot_meta.empty)
    if mode == "active"          then return active end
    if mode == "active_nonempty" then return active and not empty end
    if mode == "active_empty"    then return active and empty end
    return Y
end

--- Helper: child by suffix
local function child_by_suffix(self, suffix)
    local id = tostring((self.config and self.config.id) or "") .. suffix
    for _, child in ipairs(self.children or {}) do if child.config and child.config.id == id then return child end end
end

-----------------------------
--- mask-box hit test
-----------------------------
function M.hit_test_outer(self, cursor_trans)
    local mask = self.config.hit_mask_box ~= N and child_by_suffix(self, "_mask"); if mask then return Base.hit_test_outer(mask, cursor_trans) end
    return Base.hit_test_outer(self, cursor_trans)
end

--- Helper: first action button
local function first_action_button(Ctrl, action)
    if action == "delete" or action == "secondary" then action = "secondary" end
    local list = Ctrl and Ctrl.gamepad_button_action_list and Ctrl:gamepad_button_action_list(action)
    return list and list[1]
end

--- Helper: console key
local function console_key(Ctrl, cfg)
    local console = cfg.hint_console or (Ctrl and Ctrl.GAMEPAD_CONSOLE) or "Generic"
    if console == "Playstation" or console == "Nintendo" or console == "SteamDeck" then return console end
    if console == "Xbox"        or console == "" then return "Xbox" end
    return "Generic"
end

--- Helper: button quad
local function button_quad(console, button) return (FACE[console] and FACE[console][button]) or BUTTON_QUADS[button] or (FACE.Generic[button]) or button or "x"; end

--- Helper: console label
local function console_label(cfg, console)
    local map = cfg.hint_label_map;                                     if type(map) ~= "table" then return end
    return map[console] or map.Generic or map.Xbox
end

--- Helper: i18n_label
local function i18n_label(self)
    local cfg, gm = self.config, self.gm;                               if not (gm and cfg.hint_label_i18n_key) then return end
    local scope = cfg.hint_label_i18n_scope or "items"
    local text  = i18n(gm, { type = cfg.hint_label_i18n_type or "menu", key = scope .. "." .. cfg.hint_label_i18n_key })
    return text
end

--- Helper: sync sprite child
local function sync_quad_T(child, cfg, quad_key)
    local layout, override = cfg.quad_T_map and cfg.quad_T_map[quad_key], cfg.quad_T;  if not (layout or override) then return end
    
    local T, VT, role = child.T, child.VT, child.role;                                 if not (T and VT and role)  then return end
    local x, y     = (override and override.x) or (layout and layout.x),  (override and override.y) or (layout and layout.y)
    local w, gap   = (override and override.w) or (layout and layout.w),  cfg.quad_T_gap or 0
    local changed  = N
    
    if x then x = x + ((cfg.quad_T_index or 1) - 1)*((w or T.w) + gap);   if role.offset.x ~= x then role.offset.x, changed = x, Y end end
    if y and role.offset.y ~= y       then role.offset.y, changed = y, Y end
    if w and (T.w ~= w or VT.w ~= w)  then T.w, VT.w, changed = w, w, Y  end
    if changed and child.wake_move    then child:wake_move() end
end

--- Helper: sync_fit_axis
local function sync_fit_axis(child, cfg, quad)
    local T,    VT      = child and child.T, child and child.VT;      if not (T and VT and quad) then return end
    local _, _, qw, qh  = quad:getViewport();                         if not (qw and qh and qw > 0 and qh > 0) then return end
    local ratio         = qw/qh
    if cfg.fit_axis == "width"  and T.w then local h = T.w/ratio;     if T.h == h and VT.h == h then return end; T.h, VT.h = h, h end
    if cfg.fit_axis == "height" and T.h then local w = T.h*ratio;     if T.w == w and VT.w == w then return end; T.w, VT.w = w, w end
    if child.wake_move then child:wake_move() end
end

local function sync_sprite(child, atlas_key, quad_key)
    local cfg = child and child.config;         if not (cfg and atlas_key and quad_key) then return end
    local atlas = child.gm and child.gm.T_atlas and child.gm.T_atlas[atlas_key];    if not (atlas and atlas.quads and atlas.quads[quad_key]) then return end
    sync_quad_T(child, cfg, quad_key)
    if cfg.atlas_key == atlas_key and cfg.quad_key == quad_key then return sync_fit_axis(child, cfg, child.sprite_quad or atlas:get_quad(quad_key)) end
    cfg.atlas_key,      cfg.quad_key      = atlas_key, quad_key
    child.sprite_atlas, child.sprite_img  = atlas, atlas.image

    child.sprite_quad     = atlas:get_quad(quad_key)
    child.sprite_metrics  = child.sprite_quad and Metrics.quad_metrics(child.sprite_quad)
    sync_fit_axis(child, cfg, child.sprite_quad)
end

--- Helper: mask sprite ref
local function mask_sprite_ref(cfg, icon_quad)
    local map, item = cfg.hint_mask_map
    if type(map) == "table" then item = map[icon_quad] end
    if type(item) == "string" then return cfg.hint_mask_atlas_key, item end
    if type(item) == "table" then return item.atlas_key or cfg.hint_mask_atlas_key, item.quad_key or item.key end
    if cfg.hint_mask_quad_key then return cfg.hint_mask_atlas_key, cfg.hint_mask_quad_key end
    if cfg.hint_mask_suffix and icon_quad then return cfg.hint_mask_atlas_key, icon_quad .. cfg.hint_mask_suffix end
end

--- Helper: sync glyph
local function sync_glyph(self, Ctrl)
    local cfg, console = self.config, console_key(Ctrl, self.config)

    if cfg.hint_icon_quad_keys then
        local atlas, mask_quad = mask_sprite_ref(cfg, cfg.hint_icon_quad_keys[1])
        sync_sprite(child_by_suffix(self, "_mask"), atlas, mask_quad)
        for i, quad in ipairs(cfg.hint_icon_quad_keys) do sync_sprite(child_by_suffix(self, "_icon" .. i), cfg.hint_atlas_key or "console_pack", quad) end
        return
    end

    local button  = cfg.hid_button or first_action_button(Ctrl, cfg.hid_action)
    local quad    = cfg.hint_icon_quad_key or button_quad(console, button)
    local atlas, mask_quad = mask_sprite_ref(cfg, quad)
    sync_sprite(child_by_suffix(self, "_mask"), atlas, mask_quad)
    sync_sprite(child_by_suffix(self, "_icon1"), cfg.hint_atlas_key or "console_pack", quad)
end

--- Helper: sync label child
local function sync_label(self, Ctrl)
    local text   = console_label(self.config, console_key(Ctrl, self.config)) or i18n_label(self); if not text then return end
    local child  = child_by_suffix(self, "_label");                              if not child then return end
    local cfg    = child.config;                                                 if not cfg then return end
    local textfx = cfg.textfx
    if textfx then if textfx.text ~= text then textfx.text = text end; return end
    if cfg.text ~= text then cfg.text = text end
end

--- Helper: sync label language x offset
local function sync_label_x(self)
    local map = self.config.label_x_offset_by_lang;                            if type(map) ~= "table" then return end
    local child = child_by_suffix(self, "_label");                            if not (child and child.role and child.role.offset) then return end
    local offset = child.role.offset
    if child._hint_label_base_x == nil then child._hint_label_base_x = offset.x end
    local lang = self.gm and self.gm.selected_lang
    local x = child._hint_label_base_x + (map[lang and lang.key] or 0);         if offset.x == x then return end
    offset.x = x
    if child.move_with_major then child:move_with_major(0) end
end

-----------------------------
--- update hint visibility
----------------------------
function M.update(self)
    local Ctrl = self.gm and self.gm.CTRL
    sync_glyph(self, Ctrl)
    sync_label(self, Ctrl)
    sync_label_x(self)
    local visible = show_when_visible(Ctrl, self.config and self.config.show_when) and parent_state_visible(self, self.config and self.config.show_when_parent)
    sync_parent_cut_in(self, visible)
    set_visible(self, visible)
    if visible and self.config.hint_icon_show_when then
        local icon_visible = show_when_visible(Ctrl, self.config.hint_icon_show_when)
        for i in ipairs(self.config.hint_icon_quad_keys or { self.config.hint_icon_quad_key or true }) do set_visible(child_by_suffix(self, "_icon" .. i), icon_visible) end
    end
end

return M
