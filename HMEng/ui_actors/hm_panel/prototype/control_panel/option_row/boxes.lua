local C      = require("HMfns.animate.color.color_const")
local Layout = require("HMEng.ui_actors.hm_panel.prototype.control_panel.option_row.layout")

local min = math.min

local CUI = C.UI
local ctl = CUI.TEXT_LIGHT
local N   = false

local M = {}

local _text_offset_y  = -0.7
local _ctrl_offset_y  = 0.2
local _max_ctrl_w     = 3.

-----------------------------
--- text widget helpers
----------------------------------
--- Helper: _title
local function _title(text, x, y, w, args)
    args = args or {}
    return {
        --- basics
        style  = "text_widget",              T = { x = x, y = y, w = w or 1.8, h = args.h or 0.28 },
        id     = args.id,

        --- hit settings
        button      = N,                     can_click = N,
        can_hover   = N,                     can_drag  = N,
        can_collide = N,

        --- text settings
        text = text,                         text_scale = args.text_scale or 0.3,
        text_color = args.text_color or ctl, text_shadow = args.text_shadow ~= N,
        text_wrap = args.text_wrap ~= N,     text_align = args.text_align or { x = "left", y = "middle" },
        text_maxw = args.text_maxw,
    }
end

--- Helper: label_textfx
local function label_textfx(id, text, args)
    args = args or {}
    local title = _title(text, 0, 1.2, args.w or 3, {
        id          = id,                        text_scale  = args.text_scale or 0.5,
        text_color  = args.text_color or ctl,    text_align  = args.text_align,
        text_wrap   = N,                         text_maxw   = Layout.label_text_maxw(args),
    })
    title.lang = args.lang
    return title
end

-----------------------------
--- container helpers
----------------------------------
--- Helper: _box
local function _box(id, T, children, textfx, align)
    local t_align, c_align = align and align.textfx, align and align.child
    return { --- basic settings
        style = "conceptual_box",       id = id,             T = T,

        --- hit settings
        button = N,                     can_hover = N,       can_click = N,
        can_drag = N,                   can_collide = N,

        --- textfx & child_widgets
        textfx = textfx,                child_widgets = children,

        --- alignment
        textfx_align = t_align,         child_align = c_align,
    }
end

---____________________________
--- main: text_box
---______________________________________
function M.text_box(args, row_h)
    local T = args.label_box_T or { x = args.label_x or 0.62, y = args.label_y or _text_offset_y, w = Layout.label_w(args), h = row_h }
    return _box(args.id .. "_textfx_box", T, { label_textfx(args.id .. "_label_text", args.label, { w = T.w, text_scale = Layout.label_fit_scale(args), text_align = args.label_text_align, lang = args.label_lang or args.lang, label_text_inset = args.label_text_inset }) }, nil, { child = args.label_align or args.label_textfx_align })
end

---____________________________
--- main: control_widget_box
---______________________________________
function M.control_widget_box(args, row_h)
    local T  = args.control_box_T or { x = Layout.control_x(args), y = args.control_y or _ctrl_offset_y, w = args.control_w or 2.5, h = row_h }
    T.w      = min(T.w, args.control_max_w or _max_ctrl_w)
    return _box(args.id .. "_control_widget_box", T, args.child_widgets, nil, { child = args.control_align })
end

return M
