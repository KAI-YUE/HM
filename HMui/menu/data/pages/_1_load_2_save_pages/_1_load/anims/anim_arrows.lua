local Motion    = require("HMEng.ui_actors.common.motion")
local PhysicsMotion = require("HMEng.ui_actors.common.physics_motion")
local Tree      = require("HMEng.ui_actors.common.tree")
local AnimUtils = require("HMfns.animate.transitions.anim_utils")

local rand = math.random
local max = math.max

local Y = true

local M = {}

local _queue             = "load_menu_enter"
local _arrow_start       = 0.16
local _arrow_gap         = 0.05
local _arrow_fade_time   = 0.16
local _spring_step_floor = 0.02
local _spring_drama      = 0.5
local _time_dilation     = 4.0

local _cache_draw_offset   = Motion.cache_draw_offset
local _restore_draw_offset = Motion.restore_draw_offset

local _drop_enter = {
    load_page_next = {
        from_y = -7.4, string_length = 8.3, drama = 1.08, time_dilation = 1.0,
        spring = {
            { t = 0.18, y_len =  0.32 + 0.74*rand(), r =  0.8 + rand(),  ease = "sine", string_alpha = 0.74 },
            { t = 0.14, y_len = -0.20 - 0.38*rand(), r = -0.7 - 0.7*rand(),  ease = "sine", string_alpha = 0.68 },
            { t = 0.12, y_len =  0.14 + 0.28*rand(), r =  0.6 + 0.6*rand(),  ease = "sine", string_alpha = 0.54 },
            { t = 0.10, y_len = -0.06 - 0.16*rand(), r = -0.5 - 0.5*rand(),  ease = "sine", string_alpha = 0.40 },
            { t = 0.09, y_len =  0.04 + 0.09*rand(), r =  0.28 + 0.3*rand(), ease = "sine", string_alpha = 0.26 },
            { t = 0.08, y_len = -0.02 - 0.05*rand(), r = -0.14 - 0.2*rand(), ease = "sine", string_alpha = 0.14 },
            { t = 0.09, y_len =  0.00,               r =  0.00, ease = "sine", string_alpha = 0.00 },
        },
    },
    load_page_prev = {
        from_y = -5.8, string_length = 6.9, drama = 0.72, time_dilation = 1.06,
        spring = {
            { t = 0.17, y_len =  0.22 + 0.52*rand(), r = -0.6 - rand(),  ease = "sine", string_alpha = 0.72 },
            { t = 0.13, y_len = -0.14 - 0.28*rand(), r =  0.9 + rand(),  ease = "sine", string_alpha = 0.62 },
            { t = 0.11, y_len =  0.10 + 0.20*rand(), r = -0.5 - 0.5*rand(),  ease = "sine", string_alpha = 0.48 },
            { t = 0.09, y_len = -0.04 - 0.12*rand(), r =  0.5 + 0.3*rand(),  ease = "sine", string_alpha = 0.34 },
            { t = 0.08, y_len =  0.03 + 0.07*rand(), r = -0.18 - 0.2*rand(), ease = "sine", string_alpha = 0.22 },
            { t = 0.07, y_len = -0.01 - 0.04*rand(), r =  0.10 + 0.1*rand(), ease = "sine", string_alpha = 0.12 },
            { t = 0.08, y_len =  0.00,               r =  0.00, ease = "sine", string_alpha = 0.00 },
        },
    },
    load_page_slide_bar = {
        fade_only = Y,
        delay = 0.4,
        fade_time = 0.58,
        time_dilation = 1.0,
    },
}

local _enter_order = {
    { id = "load_page_next",      preset = _drop_enter.load_page_next },
    { id = "load_page_slide_bar", preset = _drop_enter.load_page_slide_bar },
    { id = "load_page_prev",      preset = _drop_enter.load_page_prev },
}


--- Helper: _after | _ease | _drama | _dilation | _dt
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end
local function _ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _queue) end
local function _drama(preset) return _spring_drama*(preset.drama or 1) end
local function _dilation(preset) return _time_dilation*(preset.time_dilation or 1) end
local function _dt(preset, t) return max((t or 0)*_dilation(preset), _spring_step_floor) end

--- Helper: _normal_draw_alpha
local function _normal_draw_alpha(widget) return widget and (widget.page_switch_draw_alpha or widget.draw_alpha) end

--- Helper: step_offset 
local function _step_offset(preset, step)
    return PhysicsMotion.spring_step_offset({
        string_length = preset.string_length,
        drama = _drama(preset),
    }, step)
end

--- Helper: _cache_arrow_enter
local function _cache_arrow_enter(widget)
    if not widget or widget._load_menu_arrow_drop_cached then return end
    widget._load_menu_arrow_drop = {
        draw_alpha      = _normal_draw_alpha(widget),
        draw_rotate     = widget.draw_rotate,
        pendulum_string = widget.config and widget.config.pendulum_string,
    }
    widget._load_menu_arrow_drop_cached = Y
end

--- Helper: _restore_arrow_enter
local function _restore_arrow_enter(widget)
    local normal = widget and widget._load_menu_arrow_drop
    if not normal then return Y end
    widget.draw_alpha = normal.draw_alpha
    widget.draw_rotate = normal.draw_rotate
    if widget.config then widget.config.pendulum_string = normal.pendulum_string end
    widget._load_menu_arrow_drop = nil
    widget._load_menu_arrow_drop_cached = nil
    return Y
end

--- Helper: _normal_r
local function _normal_r(widget) return ((widget and widget._load_menu_arrow_drop) or {}).draw_rotate or 0 end

--- Helper: _set_string
local function _set_string(widget, preset, alpha)
    if not widget.config or preset.fade_only then return end
    widget.config.pendulum_string = {
        alpha = alpha or 0.7,
        pivot = { x = 0, y = -(preset.string_length or 7) },
        color = { 1, 1, 1, 0.72 },
        width = 0.01,
    }
end

--- Helper: _set_enter_start
local function _set_enter_start(widget, preset)
    if not (widget and preset) then return end
    _cache_arrow_enter(widget)
    widget.draw_alpha = 0
    widget.draw_rotate = _normal_r(widget)
    if preset.fade_only then return end

    _cache_draw_offset(widget, "_load_menu_arrow_drop_offset")
    local normal = widget._load_menu_arrow_drop_offset
    widget.draw_offset_x = normal.x
    widget.draw_offset_y = normal.y + (preset.from_y or -5)
    _set_string(widget, preset, 0.04)
end

--- Helper: _drop_spring
local function _drop_spring(gm, widget, preset, delay)
    if not (widget and preset) then return delay or 0 end

    local normal = widget._load_menu_arrow_drop_offset
    local at = delay or 0

    for _, step in ipairs(preset.spring or {}) do
        _after(gm, at, function()
            if widget.REMOVED then return Y end
            local t = _dt(preset, step.t)
            local x, y = _step_offset(preset, step)
            _set_string(widget, preset, step.string_alpha)
            _ease(gm, widget, "draw_offset_x", normal.x + x, t, step.ease or "sine")
            _ease(gm, widget, "draw_offset_y", normal.y + y, t, step.ease or "sine")
            if step.r then return _ease(gm, widget, "draw_rotate", _normal_r(widget) + step.r, t, step.ease or "sine") end
            return Y
        end)
        at = at + _dt(preset, step.t)
    end

    _after(gm, at + 0.04, function()
        _restore_draw_offset(widget, "_load_menu_arrow_drop_offset")
        return _restore_arrow_enter(widget)
    end)

    return at + 0.04
end

--- Helper: _fade_in
local function _fade_in(gm, widget, preset, delay)
    if not widget then return end
    _after(gm, delay, function()
        if widget.REMOVED then return Y end
        return _ease(gm, widget, "draw_alpha", widget._load_menu_arrow_drop.draw_alpha or 1, _dt(preset, preset.fade_time or _arrow_fade_time), "lerp")
    end)
end

--- Helper: _drop_in_arrow_part
local function _drop_in_arrow_part(gm, widget, preset, delay)
    if not (widget and preset) then return end
    local start = (delay or 0) + (preset.delay or 0)*_dilation(preset)
    _fade_in(gm, widget, preset, start)
    if preset.fade_only then
        _after(gm, start + _dt(preset, preset.fade_time or _arrow_fade_time) + 0.04, function() return _restore_arrow_enter(widget) end)
        return
    end
    _drop_spring(gm, widget, preset, start)
end

--- Helper: fade_in
function M.fade_in(gm, root)
    for _, enter in ipairs(_enter_order) do _set_enter_start(Tree.find_child_by_id(root, enter.id), enter.preset) end
    for i, enter in ipairs(_enter_order) do _drop_in_arrow_part(gm, Tree.find_child_by_id(root, enter.id), enter.preset, (_arrow_start + _arrow_gap*(i - 1))*_dilation(enter.preset)) end
end

return M
