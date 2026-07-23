local HintBtn       = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn")

local Y, N = true, false

----------------------------------------------
--- universal hint_btn config
----------------------------------------------
local btn_shadow_under_mask = N
local back_T                = { x = .2, y = 1.4, w = 2.8, h = 0.52, r = 0 }

local M = {}

--- Helpers: default | with
local function _default(value, fallback)  if value == nil then return fallback end; return value end
local function _with(base, args)          for k, v in pairs(args or {}) do base[k] = v end; return base end

--- Helper: composite hint
local function _composite_hint(args)
    args = args or {}
    args.btn_shadow_under_mask = _default(args.btn_shadow_under_mask, btn_shadow_under_mask)
    return HintBtn.composite(args)
end

-----------------------------
--- composite presets
-----------------------------
function M.back(args)
    local defaults = { T = back_T, hid_action = "cancel", label_w = 1.9, show_when = "controller", gamepad_focus = N, shape = "circle" }
    if not args or args.label == nil then defaults.label, defaults.hint_label_i18n_key = "Back", "back" end
    return _composite_hint(_with(defaults, args))
end
function M.done(args)
    local defaults = { hid_action = "done", label_w = 2.2, shape = "circle" }
    if not args or args.label == nil then defaults.label, defaults.hint_label_i18n_key = "Apply", "apply" end
    return _composite_hint(_with(defaults, args))
end
function M.confirm(args)
    local defaults = { hid_action = "confirm", label_w = 2.2, show_when = "controller", shape = "circle" }
    if not args or args.label == nil then defaults.label, defaults.hint_label_i18n_key = "Confirm", "confirm" end
    return _composite_hint(_with(defaults, args))
end
function M.cancel(args)
    local defaults = { hid_action = "cancel", label_w = 2.2, show_when = "controller", shape = "circle" }
    if not args or args.label == nil then defaults.label, defaults.hint_label_i18n_key = "Cancel", "cancel" end
    return _composite_hint(_with(defaults, args))
end
function M.delete(args)
    local defaults = { hid_action = "delete", label_w = 2.2, show_when = "controller", shape = "circle" }
    if not args or args.label == nil then defaults.label, defaults.hint_label_i18n_key = "Delete", "delete" end
    return _composite_hint(_with(defaults, args))
end
function M.info(args)
    local defaults = { hid_action = "secondary", label_w = 1.9, show_when = "controller", shape = "circle" }
    if not args or args.label == nil then defaults.label, defaults.hint_label_i18n_key = "Info", "info" end
    return _composite_hint(_with(defaults, args))
end
function M.option(args) return _composite_hint(_with({ hid_action = "start",  label_w = 2.2, hint_icon_quad_key = "pad_option", base_T = { x = 0.3, y = 0.22, w = 0.42 } }, args)) end

-----------------------------
--- bumper
-----------------------------
function M.bumper(args)
    args = args or {}
    local labels, icon = args.labels, args.icon
    return HintBtn.build({
        --- basics
        id             = args.id,                                   T          = args.T,
        label          = labels.Generic,                            hint_mask  = args.hint_mask ~= N,
        button_w       = args.button_w or 1,                        icon_w     = 1,
        label_on_btn   = Y,                                         label_h    = 0.52,
        text_align     = { x = "center", y = "middle" },

        --- draw setting
        options_tab_step    = args.step,                             hid_action           = args.hid_action,
        hint_btn_quad_key   = icon,                                  hint_icon            = N,
        hint_label_map      = labels,                                hint_mask_quad_key   = args.hint_mask_quad_key or (icon .. "_mask"),
        hint_mask_cfg       = args.hint_mask_cfg,                    hint_mask_map        = args.hint_mask_map,
        page_draw_layer     = args.page_draw_layer,                  opt_tab_cut_in_sync  = args.opt_tab_cut_in_sync ~= N,
        hint_enter_fade     = args.hint_enter_fade or N,             hint_enter_wipe      = args.hint_enter_wipe ~= N,

        --- optional overrides
        btn_tint     = args.btn_tint,                                btn_shadow  = args.btn_shadow,
        btn_shadow_under_mask = _default(args.btn_shadow_under_mask, btn_shadow_under_mask),
        btn_shadow_same_layer = args.btn_shadow_same_layer,
        text_color   = args.text_color,                              mask_tint   = args.mask_tint,
        mask_x       = args.mask_x,                                  mask_y      = args.mask_y,
        mask_w       = args.mask_w,                                  mask_h      = args.mask_h,
        mask_w_pad   = args.mask_w_pad,                              mask_h_pad  = args.mask_h_pad,
    })
end

return M
