local C, CUtils  = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local OptionRow  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row")
local State      = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local Backend    = require("HMEng.ui_actors.hm_panel.prototype.control_panel.lr_selector.backend")

local lerp_colors  = CUtils.lerp_colors
local max, min     = math.max, math.min

local CUI = C.UI
local ck  = C.BLACK
local cwd = lerp_colors(CUI.WIDGET_DARK, ck, 0.7)
local ctl, cia = CUI.TEXT_LIGHT, CUI.INACTIVE

local Y, N = true, false

local M = {}

local _arrow_w,       _control_y = 0.32, 0.28
local _gap,           _base_y    = 0.64, 0.1
local _rrect_chip_h,  _rrect_pad = 0.8,  0.35

--- Helper: arrow
local function arrow(id, quad_key, x, state, dir, on_change, disabled)
    local y_bias = (dir == -1 and _base_y + 0.01) or _base_y
    return {
        --- basic settings
        style = "sprite_in_page",               T        = { x = x, y = y_bias, r = 0.0, w = _arrow_w },
        id    = id,                             quad_key = quad_key,

        --- hit settings
        button      = not disabled,             can_hover   = not disabled,
        can_click   = not disabled,             can_drag    = N,
        hover_zoom  = disabled and 1 or 1.12,   hover_shake = not disabled and { x = 0.02, y = 0.015, r = 0.04, speed = 32, settle = 8 } or N,
        hit_padding = { x = 0.19, y = 0.12 },

        --- color settings
        tint = disabled and cia,                sprite_color = disabled and cia,
        shadow_color = disabled and { 0, 0, 0, 0.12 },

        hook_fn = Backend.select_option(state, dir, on_change),
    }
end

--- Helper: value_text_box_T | value_chip_x
local function value_text_box_T(layout, args)  return { x = 0, w = (args.value_text_box_w_factor or 1.5)*layout.w } end
local function value_chip_x(text_box_T, gap)   return _arrow_w + gap - (text_box_T.x or 0) end

--- Helper: value_arrow_x
local function value_arrow_x(chip_x, text_box_T, side, gap)
    local left  = chip_x + (text_box_T.x or 0)
    local right = left   + (text_box_T.w or 0)
    return side < 0 and (left - _arrow_w) or (right + gap)
end

--- Helper: value_text_maxw | value_chip_T
local function value_text_maxw(layout, text_box_T, args) return max(0.1, args.value_text_maxw or (text_box_T and text_box_T.w) or layout.w) end
local function value_chip_T(prev_x, next_x)              local left = prev_x + _arrow_w; return { x = left - _rrect_pad, y = 0., w = max(0.1, next_x - left + 2*_rrect_pad), h = _rrect_chip_h } end

--- Helper: value_chip_text_inset
local function value_chip_text_inset(chip_T, args)
    local inset = args.value_chip_text_inset or args.value_text_inset or 0
    return min(inset, max(0, 0.5*((chip_T and chip_T.w) or 0) - _rrect_pad - 0.05))
end

--- Helper: value_chip_text_box_T
local function value_chip_text_box_T(chip_T, args)
    local inset = _rrect_pad + value_chip_text_inset(chip_T, args)
    return { x = inset, y = 0, w = max(0.1, chip_T.w - 2*inset), h = chip_T.h }
end

--- Helper: value_chip
local function value_chip(id, option, prev_x, next_x, layout, args)
    local fill_color, text_color = cwd, ctl
    local chip_T      = value_chip_T(prev_x, next_x)
    local text_box_T  = value_chip_text_box_T(chip_T, args)
    return {
        --- basic settings
        style = "round_rect",                T = chip_T,
        id    = id,                          round_radius = args.value_chip_round_radius,

        --- hit settings
        button = N,                          can_hover = N,
        can_click = N,

        --- color settings
        fill_color = fill_color,             idle_color = { fill_color = fill_color, text_color = text_color },

        --- text settings
        text = Backend.option_label(option), lang = Backend.option_lang(option),
        text_scale = layout.text_scale,      text_shadow = N,
        text_color = text_color,

        text_padding = { x = 0, y = 0 },     text_align = { x = "center", y = "middle" },
        text_box_T = text_box_T,             text_wrap = args.value_text_wrap ~= N,
        text_maxw = value_text_maxw(layout,  text_box_T, args),
    }
end

--- Helper: make
function M.make(args)
    args = args or {}
    local id, value   = args.id or "lr_selector", args.value or ""
    local options     = args.options or {}
    local option      = Backend.display_option(options, value)
    local layout      = Backend.value_layout(Backend.widest_value_text(option, args), args)
    local text_box_T  = value_text_box_T(layout, args)
    local gap         = args.value_gap or _gap

    local chip_x, on_change  = value_chip_x(text_box_T, gap),              State.wrap_on_change(args.on_change)
    local prev_x, next_x     = value_arrow_x(chip_x, text_box_T, -1, gap), value_arrow_x(chip_x, text_box_T,  1, gap)
    local base_w, state      = next_x, { options = options, idx = Backend.selected_index(options, value), value_id = id .. "_value", refresh = args.refresh_state }
    local arrows_disabled    = args.arrows_disabled

    args.control_w     = args.control_w or base_w
    args.control_y     = args.control_y or _control_y
    args.control_align = args.control_align or { x = "center", y = "middle" }

    return OptionRow.make({
        --- basic settings
        id    = id,                             T = args.T,
        label = args.label,

        --- i18n settings
        i18n_type  = args.i18n_type,            description_key = args.description_key,
        i18n_scope = args.i18n_scope,

        --- label fit settings
        lang         = args.lang,               tile_size             = args.tile_size,
        label_lang   = args.label_lang,         label_tile_size       = args.label_tile_size,
        label_w      = args.label_w,            label_char_w_factor   = args.label_char_w_factor,
        label_min_w  = args.label_min_w,        label_stretch_factor  = args.label_stretch_factor,
        label_max_w  = args.label_max_w,        label_box_T           = args.label_box_T,

        --- alignment settings
        label_align   = args.label_align,       label_text_align  = args.label_text_align,
        control_w     = args.control_w,         control_y         = args.control_y,
        control_align = args.control_align,     control_box_T     = args.control_box_T,
        control_max_w = args.control_max_w or args.control_w,
        control_gap   = args.control_gap,
        focus_args    = { type = "lr_row", prev_id = id .. "_prev", next_id = id .. "_next", nav = "wide" },

        --- paint settings
        paint = args.paint,                     paint_seed_entry = args.paint_seed_entry,
        widget_dist = args.widget_dist,

        --- child_widgets
        child_widgets = {
            value_chip(id .. "_value", option, prev_x, next_x, layout, args),
            arrow(id .. "_prev", "arrow-7", prev_x, state, -1, on_change, arrows_disabled),
            arrow(id .. "_next", "arrow-8", next_x, state, 1, on_change, arrows_disabled),
        },
    })
end

return M
