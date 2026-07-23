local C         = require("HMfns.animate.color.color_const")
local OptionRow = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row")
local State     = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local Backend   = require("HMEng.ui_actors.hm_panel.prototype.control_panel.on_off_switcher.backend")

local rand = math.random
local abs  = math.abs

local CUI = C.UI
local ctl = CUI.TEXT_LIGHT
local ccrm = C.CREAM
local ck, cw  = C.BLACK, C.WHITE
local ca, ci  = CUI.ACTIVE, CUI.INACTIVE

local Y, N = true, false

local M = {}

local _paper_w,   _paper_r  = 1.4, 0.5*(rand() - 0.5)
local _paper_gap, _paper_y  = 0.08, 0.02
local _clip_w,   _clip_y    = 0.38, -0.16
local _clip_r               = 0.
local _text_y,  _text_h     = -0.09, 0.4*_paper_w
local _text_inset           = 0.4
local _text_scale           = 0.5
local _text_squish          = 1

--- Helper: paper_tint | text_color | option_text_scale
local function paper_tint(selected) return selected and ca or ci end
local function text_color(_)        return ck end
local function option_text_scale(_, args) return args.value_text_scale or _text_scale end

--- Helper: option_r
local function option_r(selected, args) local r = abs(args.value_paper_r or _paper_r); return selected and -r or r end

--- Helper: paper_option
local function paper_option(id, text, selected, lang, x, layout, state, value, on_change, args)
    local text_inset = args.value_text_inset or _text_inset
    local text_box_T = {
        x = text_inset,              y = 0,
        w = _paper_w - 2*text_inset, h = args.value_text_h or _text_h,
    }

    return {
        --- basic settings
        style     = "sprite_in_page",     T         = { x = x, y = _paper_y, w = _paper_w, r = option_r(selected, args) },
        id        = id,                   quad_key  = "on-paper",
        fit_axis  = "width",

        --- hit settings
        button           = Y,             can_hover     = Y,
        can_click        = Y,             can_drag      = N,
        hover_zoom       = 1,             hit_padding   = { x = 0.06, y = 0.10 },
        hover_shake      = N,             hover_jitter  = { amount = 0.05, r = 0.035 },
        hover_tint       = 0.18,          parent_hover_tint = N,
        hover_safe_time  = 0.18,          hook_fn       = Backend.select_option(state, value, on_change),
        no_press_squash  = Y,

        --- color settings
        shadow = Y,                       shadow_color  = { 0, 0, 0, 0.22 },
        tint = paper_tint(selected),      sprite_color  = paper_tint(selected),
        idle_tint = paper_tint(N),        selected_tint = paper_tint(Y),
        widget_dist = 0.8,

        --- text settings
        text = text,                      lang = lang,
        text_scale = option_text_scale(layout, args),
        text_squish = args.value_text_squish or _text_squish,

        --- text color
        text_shadow = N,                  text_color = text_color(selected),
        text_alpha = 1,
        idle_text_color = text_color(N),  selected_text_color = text_color(Y),

        --- text alignment
        text_wrap = N,                    text_align = { x = "center", y = "middle" },
        text_padding = { x = 0, y = 0 },  text_box_T = text_box_T,
        text_maxw = args.value_text_maxw or math.max(0.1, text_box_T.w),
    }
end

--- Helper: clip_decorator
local function clip_decorator(id, x)
    return {
        --- basic settings
        style = "sprite_in_page",      T = { x = x, y = _clip_y, r = _clip_r, w = _clip_w },
        id = id,                       quad_key = "clip-3",

        --- hit settings
        button = N,                    can_hover = N,
        can_click = N,                 can_drag = N,

        --- color settings
        shadow = Y,                    shadow_color = { 0, 0, 0, 0.22 },
        tint = ctl,                    sprite_color = cw,
    }
end

--- Helper: control_w
local function control_w(args) return args.control_w or (2*_paper_w + _paper_gap) end

--- Helper: make
function M.make(args)
    args = args or {}
    local id                 = args.id or "on_off_switcher"
    local on_text, off_text  = Backend.option_labels(args)
    local layout             = Backend.value_layout(#on_text >= #off_text and on_text or off_text, args)

    local state              = { on = (args.on == Y), on_id = id .. "_on", off_id = id .. "_off", clip_id = id .. "_clip" }
    state.on_text_id, state.off_text_id = state.on_id, state.off_id

    local on_change     = State.wrap_on_change(args.on_change)
    args.control_w      = control_w(args)
    args.control_align  = args.control_align or { x = "center", y = "middle" }
    args.text_scale     = 1

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
        on_change     = on_change,
        focus_args    = { type = "switch_row", on_id = state.on_id, off_id = state.off_id, nav = "wide" },

        --- paint settings
        paint = args.paint,                  paint_seed_entry  = args.paint_seed_entry,
        widget_dist = args.widget_dist,

        --- child_widgets
        child_widgets = {
            paper_option(state.on_id, on_text, state.on, Backend.option_lang(args), 0, layout, state, Y, on_change, args),
            paper_option(state.off_id, off_text, not state.on, Backend.option_lang(args), _paper_w + _paper_gap, layout, state, N, on_change, args),
            clip_decorator(id .. "_clip", _paper_w - 0.5*_clip_w + 0.5*_paper_gap),
        },
    })
end

return M
