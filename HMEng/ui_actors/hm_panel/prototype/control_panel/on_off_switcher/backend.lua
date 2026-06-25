local TextFit = require("HMfns.utils.format.text_fit")

local Y, N = true, false

local M = {}

local _text_scale = 0.28
local _rotate_time = 0.18
local _clip_jitter_amount, _clip_jitter_r = 0.1, 0.1

--- value_fit_args
function M.value_fit_args(args)
    args = args or {}
    return {
        text_scale = args.value_text_scale or _text_scale,
        char_w_factor = args.value_char_w_factor or 0.62,
        stretch_factor = args.value_stretch_factor,
        min_w = args.value_min_w or 0.78,
        max_w = args.value_max_w or 1.55,
        w = args.value_w,
    }
end

--- value_layout | option_labels | option_lang
function M.value_layout(text, args) return TextFit.layout(text, M.value_fit_args(args)) end
function M.option_labels(args)      args = args or {};    return args.on_label or "ON", args.off_label or "OFF" end
function M.option_lang(args)        return args and (args.value_lang or args.lang) end

--- child_by_id
function M.child_by_id(parent, id)
    for _, child in ipairs((parent and parent.children) or {}) do
        if child.config and child.config.id == id then return child end
        local found = M.child_by_id(child, id)
        if found then return found end
    end
end

--- sync_option
function M.sync_option(widget, selected)
    if not (widget and widget.config) then return end
    widget.config.selected = selected and Y or N
    widget.config.tint = (selected and widget.config.selected_tint or widget.config.idle_tint) or widget.config.tint
    widget.config.sprite_color = widget.config.tint
end

--- sync_text
function M.sync_text(widget, selected)
    if not (widget and widget.config) then return end
    widget.config.text_color = (selected and widget.config.selected_text_color or widget.config.idle_text_color) or widget.config.text_color
end

--- jitter_clip
local function jitter_clip(parent, state)
    local clip = M.child_by_id(parent, state.clip_id)
    if clip and clip.jitter_me then clip:jitter_me(_clip_jitter_amount, _clip_jitter_r) end
end

--- switch_r
local function switch_r(widget, selected)
    local T = widget and widget.T;    if not T then return end
    widget.on_off_switcher_r = widget.on_off_switcher_r or math.abs(T.r or 0)
    return selected and -widget.on_off_switcher_r or widget.on_off_switcher_r
end

--- ease_switch_r
local function ease_switch_r(gm, widget, selected)
    local T, to = widget and widget.T, switch_r(widget, selected)
    if not (T and to) then return end
    local EM = gm and gm.E_MANAGER
    if not EM then T.r = to; return end
    EM:enqueue_event({ trigger = "ease", ease = "sine", blockable = N, blocking = N, ref_table = T, ref_value = "r", ease_to = to, delay = _rotate_time })
end

--- sync_switcher
function M.sync_switcher(parent, state, gm)
    local on_selected = state.on == Y
    local on_widget, off_widget = M.child_by_id(parent, state.on_id), M.child_by_id(parent, state.off_id)
    M.sync_option(on_widget, on_selected)
    M.sync_option(off_widget, not on_selected)
    ease_switch_r(gm, on_widget, on_selected)
    ease_switch_r(gm, off_widget, not on_selected)
    jitter_clip(parent, state)
    M.sync_text(M.child_by_id(parent, state.on_text_id), on_selected)
    M.sync_text(M.child_by_id(parent, state.off_text_id), not on_selected)
end

---____________________________
--- main: select_option
---______________________________________
function M.select_option(state, value, on_change)
    return function(gm, widget)
        if state.on == value then return Y end
        state.on = value and Y or N
        M.sync_switcher(widget and widget.parent, state, gm)
        if on_change then on_change(gm, widget, state.on) end
        return Y
    end
end

return M
