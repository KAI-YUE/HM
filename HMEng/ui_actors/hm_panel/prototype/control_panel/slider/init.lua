local C         = require("HMfns.animate.color.color_const")
local OptionRow = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row")
local State     = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local Backend   = require("HMEng.ui_actors.hm_panel.prototype.control_panel.slider.backend")

local CUI = C.UI
local ctl = CUI.TEXT_LIGHT
local cw  = C.WHITE

local Y, N = true, false

local M = {}

local _slider_txt_scale                = 0.5
local _h,          _steps              = 0.6, 10
local _track_x,    _track_y, _track_h  = 0.85, 1., _h
local _w_h_ratio,  _knob_w             = 5.2, _h      --- ad-hoc setting for a "bar" sprite
local _visual_min, _visual_max         = 0.05, 0.85

--- Helper: bar
local function bar(id, quad_key, T, tint)
    return { --- basic settings
        style     = "sprite_in_page",      T = T,                       id = id,
        quad_key  = quad_key,              fit_axis  = "height",

        --- hit settings
        button = N,                        can_hover = N,               can_click = N,
        can_drag = N,                      widget_dist = 0.85,

        --- color settings
        shadow = Y,                        shadow_color = { 0, 0, 0, 0.20 }, tint = tint,
        sprite_color = tint,
    }
end

--- Helper: _bar
local function _bar(id)  return bar(id .. "bar", "bar",  { x = _track_x, y = _track_y,  h = _track_h }, ctl) end

--- Helper: value_text
local function value_text(id, args)
    return {
        --- basic settings
        style = "text_widget",          T = { x = _track_x + _w_h_ratio * _h + 0.15, y = _track_y + 0.1 , w = 0.75, h = 0.34 },
        id = id .. "_value_text",

        --- hit settings
        button = N,                     can_hover = N,
        can_click = N,                  can_drag = N,

        --- text settings
        text_scale = _slider_txt_scale, text = Backend.display_value(args),
        text_color = ctl,               text_align = { x = "center", y = "middle" },
        text_shadow = N,
    }
end

--- Helper: control_w
local function control_w(args) return args.control_w or (_track_x + _w_h_ratio * _h ) end

--- Helper: knob
local function knob(id, args)
    local v = Backend.visual_value(Backend.normalized_value(args))
    local x,     y      = _track_x + _w_h_ratio * _h * v - _knob_w * 0.5, _track_y - 0.05
    local min_x, max_x  = _track_x + _w_h_ratio * _h * _visual_min - _knob_w * 0.5, _track_x + _w_h_ratio * _h * _visual_max - _knob_w * 0.5
    return {
        --- basic settings
        style = "sprite_in_page",           T = { x = x, y = y, w = 1.2*_knob_w },
        id = id .. "_knob",                 quad_key = "slider1",

        --- hit settings
        button = N,                         can_hover = Y,
        can_click = N,                      can_drag = Y,
        hit_padding = { x = 0.2, y = 0.2 },

        --- hover settings
        hover_zoom = 1.02,                  hover_shake = { x = 0.035, y = 0.02, r = 0.08, speed = 34, settle = 8 },
        description_key = args.description_key,
        finish_reveal_b4_fade = args.finish_reveal_b4_fade,
        hover_dwell_by_text_speed = args.hover_dwell_by_text_speed,
        description_lang = args.description_lang,
        i18n_type = args.i18n_type,          i18n_scope = args.i18n_scope,

        --- color settings
        shadow = true,                      shadow_color = { 0, 0, 0, 0.25 },
        tint = cw,                          sprite_color = cw,

        --- widget settings
        widget_dist = 1.1,

        --- drag settings
        slider_drag = { min_x = min_x, max_x = max_x, start_x = x, start_y = y, y = y, steps = args.steps or _steps, value_text_id = id .. "_value_text", min_val = Backend.range_min(args), max_val = Backend.range_max(args), decimals = args.decimals or 0, on_change = State.wrap_on_change(args.on_change) },
    }
end

---____________________________
--- main: make
---______________________________________
function M.make(args)
    args = args or {}
    local id = args.id or "slider"
    args.control_w = control_w(args)
    args.control_align = args.control_align or { x = "center", y = "middle" }

    return OptionRow.make({
        --- basic settings
        id = id,                             T = args.T,
        label = args.label,

        --- i18n settings
        i18n_type = args.i18n_type,          description_key = args.description_key,
        i18n_scope = args.i18n_scope,

        --- label fit settings
        lang         = args.lang,            tile_size             = args.tile_size,
        label_lang   = args.label_lang,      label_tile_size       = args.label_tile_size,
        label_w      = args.label_w,         label_char_w_factor   = args.label_char_w_factor,
        label_min_w  = args.label_min_w,     label_stretch_factor  = args.label_stretch_factor,
        label_max_w  = args.label_max_w,     label_box_T           = args.label_box_T,

        --- alignment settings
        label_align   = args.label_align,    label_text_align  = args.label_text_align,
        control_align = args.control_align,  control_w         = args.control_w,
        focus_args = { type = "slider_row", knob_id = id .. "_knob", nav = "wide" },

        --- paint settings
        paint = args.paint,                  paint_seed_entry  = args.paint_seed_entry,
        widget_dist = args.widget_dist,

        --- child_widgets
        child_widgets = {
            _bar(id),
            knob(id, args),
            value_text(id, args),
        },
    })
end

return M
