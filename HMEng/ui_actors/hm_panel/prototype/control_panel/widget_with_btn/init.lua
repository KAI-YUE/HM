local C          = require("HMfns.animate.color.color_const")
local OptionRow  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row")
local State      = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local Backend    = require("HMEng.ui_actors.hm_panel.prototype.control_panel.widget_with_btn.backend")

local rand = math.random

local CUI = C.UI
local ca, ctl = CUI.ACTIVE, CUI.TEXT_LIGHT
local cw, ck  = C.WHITE, C.BLACK

local Y, N = true, false

local M = {}

local _paper_w,      _paper_r       = 1.25, 0.5*(rand() - 0.5)
local _paper_y                      = 0.02
local _pin_w,        _pin_y         = 0.66, -0.22
local _pin_offset_x, _pin_offset_y  = -1,   0.00
local _icon_w,       _icon_y        = 0.44, 0.5

--- Helper: icon_decorator
local function icon_decorator(id, quad_key, x, y, w, args)
    return {
        --- basic settings
        style = "sprite_in_page",      T = { x = x, y = y, w = w },
        id = id,                       quad_key = quad_key,

        --- hit settings
        button = N,                    can_hover = N,
        can_click = N,                 can_drag = N,

        --- color settings
        shadow = args.icon_shadow,     shadow_color = args.icon_shadow_color or { 0, 0, 0, 0.22 },
        tint = args.icon_tint or ctl,  sprite_color = args.icon_tint or ck,
    }
end

--- Helper: paper_button
local function paper_button(id, args, on_click)
    local button_w = args.button_w or _paper_w
    return {
        --- basic settings
        style     = "sprite_in_page",     T        = { x = 0, y = _paper_y, w = button_w, r = args.button_r or _paper_r },
        id        = id,                   quad_key = args.button_quad_key or "paper-1",
        fit_axis  = "width",

        --- hit settings
        button           = Y,             can_hover    = Y,
        can_click        = Y,             can_drag     = N,
        hover_zoom       = 1,             hit_padding  = { x = 0.08, y = 0.12 },
        hover_shake      = N,             hover_jitter = { amount = 0, r = 0.035 },
        hover_safe_time  = 0.18,          hook_fn      = Backend.button_hook(on_click),
        no_press_squash  = Y,

        --- color settings
        shadow = Y,                       shadow_color = { 0, 0, 0, 0.22 },
        tint   = args.button_tint or cw,  sprite_color = args.button_tint or ca,
        widget_dist = 0.9,

        --- sprite_overlays
        sprite_overlays = {
            {
                quad_key = args.icon_quad_key or "undo",
                x = 0.5*button_w - 0.5*_icon_w,          y = _icon_y + (args.icon_offset_y or 0), w = _icon_w,
                shadow = args.icon_shadow ~= N,          shadow_color = args.icon_shadow_color or { 0, 0, 0, 0.22 },
                tint = args.icon_tint or ctl,            sprite_color = args.icon_tint or ck,
            },
        },
    }
end

--- Helper: pin_decorator
local function pin_decorator(id, args)
    local control_w  = args.control_w or args.button_w or _paper_w
    local pin_w      = args.pin_w or _pin_w
    local pin        = icon_decorator(id, args.pin_quad_key or "pin2", 0.5*control_w - 0.5*pin_w + (args.pin_offset_x or _pin_offset_x), _pin_y + (args.pin_offset_y or _pin_offset_y), pin_w, args)
    pin.sprite_flip_x = (args.pin_flip_x ~= N)
    pin.T.r = args.pin_r or pin.T.r
    pin.shadow = args.pin_shadow == nil and pin.shadow or args.pin_shadow
    pin.shadow_color = args.pin_shadow_color or pin.shadow_color
    pin.tint = args.pin_tint or pin.tint
    pin.sprite_color = args.pin_tint or pin.sprite_color
    return pin
end

--- Helper: control_w
local function control_w(args) return args.control_w or args.button_w or _paper_w end

--- Helper: make
function M.make(args)
    args = args or {}
    local id        = args.id or "widget_with_btn"
    local raw_click = args.on_click or args.on_change
    local on_click  = (args.wrap_on_change == N) and raw_click or State.wrap_on_change(raw_click)

    args.control_w      = control_w(args)
    args.control_align  = args.control_align or { x = "center", y = "middle" }

    return OptionRow.make({
        --- basic settings
        id     = id,                            T = args.T,
        label  = args.label,

        --- i18n settings
        i18n_type  = args.i18n_type,            description_key = args.description_key,
        i18n_scope = args.i18n_scope,

        --- label fit settings
        lang          = args.lang,              tile_size             = args.tile_size,
        label_lang    = args.label_lang,        label_tile_size       = args.label_tile_size,
        label_w       = args.label_w,           label_char_w_factor   = args.label_char_w_factor,
        label_min_w   = args.label_min_w,       label_stretch_factor  = args.label_stretch_factor,
        label_max_w   = args.label_max_w,       label_box_T           = args.label_box_T,

        --- alignment settings
        label_align   = args.label_align,       label_text_align      = args.label_text_align,
        control_align = args.control_align,     control_w             = args.control_w,
        on_change     = on_click,
        focus_args    = { type = "button_row", button_id = id .. "_btn", nav = "wide" },

        --- paint settings
        paint = args.paint,                     paint_seed_entry      = args.paint_seed_entry,
        widget_dist = args.widget_dist,

        --- child_widgets (Paper + Pin)
        child_widgets = {
            paper_button(id .. "_btn", args, on_click),
            pin_decorator(id .. "_pin", args),
        },
    })
end

return M
