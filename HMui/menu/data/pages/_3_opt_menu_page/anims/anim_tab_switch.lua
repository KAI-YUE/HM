local Common = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")

local max = math.max

local Y = true

local M = {}

local _time_dilation     = 1.45
local _spring_drama      = 0.5

local _switch_delay      = 2.72
local _gap_time          = 0.04
local _string_time       = 0.18
local _pull_time         = 0.24
local _realign_time      = 0.56
local _offscreen_y       = -5.2
local _string_len        = 3.6
local _spring_step_floor = 0.02

M.switch_delay = _switch_delay*_time_dilation
M.gap_time     = _gap_time*_time_dilation

local _drop_preset  = {
    string_length = 6.8,
    from_y = _offscreen_y,
    drama = 1.0,
    time_dilation = 1.0,
    spring = {
        { t = 0.20, x =  0.14, y =  0.78, string_alpha = 0.82 },
        { t = 0.15, x = -0.10, y = -0.42, string_alpha = 0.72 },
        { t = 0.12, x =  0.07, y =  0.25, string_alpha = 0.58 },
        { t = 0.10, x = -0.04, y = -0.14, string_alpha = 0.42 },
        { t = 0.08, x =  0.02, y =  0.07, string_alpha = 0.25 },
        { t = 0.08, x =  0.00, y =  0.00, string_alpha = 0.00 },
    },
}
local _pull_preset  = {
    string_length = 6.8,
    drama = 1.0,
    time_dilation = 1.0,
    spring = {
        { t = 0.08, x =  0.02, y =  0.07, string_alpha = 0.25 },
        { t = 0.10, x = -0.04, y = -0.14, string_alpha = 0.42 },
        { t = 0.12, x =  0.07, y =  0.25, string_alpha = 0.58 },
        { t = 0.15, x = -0.10, y = -0.42, string_alpha = 0.72 },
        { t = 0.22, x =  0.00, y = _offscreen_y, string_alpha = 0.82 },
    },
}

--- Helper: _after | _ease
local function _after(gm, at, fn)             return Common.after(gm, at, fn) end
local function _ease(gm, tab, key, to, delay) return Common.ease(gm, tab, key, to, delay) end

--- Helper: _drama | _dilation | _dt | _dx | _dy | _from_y
local function _drama(preset)     return _spring_drama*(preset and preset.drama or 1) end
local function _dilation(preset)  return _time_dilation*(preset and preset.time_dilation or 1) end
local function _dt(preset, t)     return max((t or 0)*_dilation(preset), _spring_step_floor) end
local function _dx(preset, x)     return (x or 0)*_drama(preset) end
local function _dy(preset, y)     return (y or 0)*_drama(preset) end
local function _from_y(preset)    return _dy(preset, preset and preset.from_y or _offscreen_y) end

--- Helper: _set_string
local function _set_string(fx, alpha, length)
    local cfg = fx and fx.config;   if not cfg then return end
    cfg.pendulum_string = {
        alpha = alpha or 0.72,        pivot = { x = 0, y = -(length or _string_len) },
        color = { 1, 1, 1, 0.72 },    width = 0.01,
    }
end

--- Helper: _clear_string
local function _clear_string(fx) if fx and fx.config then fx.config.pendulum_string = nil end end

--- Helper: _prepare_pull_textfx
local function _prepare_pull_textfx(fx)
    local cfg = fx and fx.config;    if not cfg then return end
    fx.draw_offset_x,  fx.draw_offset_y   = fx.draw_offset_x or 0, fx.draw_offset_y or 0
    fx.draw_rotate,    fx.draw_alpha      = fx.draw_rotate or 0,   fx.draw_alpha or 1
    fx.fx_mask,        fx.text_bg_fx_mask = 0, 0
    cfg.options_tab_switch_fade,  cfg.textfx_alpha        = nil, fx.page_switch_textfx_alpha or cfg.textfx_alpha or 1
    cfg.textfx_reveal_lock_count, cfg.textfx_reveal_lock  = 0, nil
end

--- Helper: _spring_duration
local function _spring_duration(preset)
    local total = 0
    for _, step in ipairs((preset or {}).spring or {}) do total = total + _dt(preset, step.t) end
    return total
end

--- Helper: _set_drop_start
local function _set_drop_start(fx, from_y)
    if not fx then return end
    fx.draw_alpha = 0
    fx.draw_offset_x, fx.draw_offset_y = 0, from_y or _offscreen_y
    _set_string(fx, 0.04, _drop_preset.string_length)
end

--- Helper: _drop_spring
local function _drop_spring(gm, fx, at, preset)
    if not (fx and preset) then return end
    local t_at = at or 0
    for _, step in ipairs(preset.spring or {}) do
        _after(gm, t_at, function()
            if fx.REMOVED then return Y end
            local t = _dt(preset, step.t)
            _set_string(fx, step.string_alpha, preset.string_length)
            _ease(gm, fx, "draw_offset_x", _dx(preset, step.x), t)
            return _ease(gm, fx, "draw_offset_y", _dy(preset, step.y), t)
        end)
        t_at = t_at + _dt(preset, step.t)
    end
end

--- Helper: pull_duration | drop_duration
function M.pull_duration() return _spring_duration(_pull_preset) end
function M.drop_duration() return _spring_duration(_drop_preset) end

--- Helper: pull_out
function M.pull_out(gm, fx, at)
    if not fx then return end
    _prepare_pull_textfx(fx)
    local t_at = at or 0
    _after(gm, t_at, function()
        if fx.REMOVED then return Y end
        _set_string(fx, 0.82, _pull_preset.string_length)
        return Y
    end)
    for _, step in ipairs(_pull_preset.spring or {}) do
        _after(gm, t_at, function()
            if fx.REMOVED then return Y end
            local t = _dt(_pull_preset, step.t)
            _set_string(fx, step.string_alpha, _pull_preset.string_length)
            _ease(gm, fx, "draw_offset_x", _dx(_pull_preset, step.x), t)
            return _ease(gm, fx, "draw_offset_y", _dy(_pull_preset, step.y), t)
        end)
        t_at = t_at + _dt(_pull_preset, step.t)
    end
    _after(gm, t_at - _pull_time*_dilation(_pull_preset), function()
        if not fx or fx.REMOVED then return Y end
        return _ease(gm, fx, "draw_alpha", 0, _pull_time*_dilation(_pull_preset))
    end)
    _after(gm, t_at, function() _clear_string(fx); return Y end)
end

--- Helper: drop_in
function M.drop_in(gm, fx, at)
    if not fx then return end
    _set_drop_start(fx, _from_y(_drop_preset))
    _after(gm, at, function()
        if not fx or fx.REMOVED then return Y end
        return _ease(gm, fx, "draw_alpha", 1, 0.12*_dilation(_drop_preset))
    end)
    _drop_spring(gm, fx, at, _drop_preset)
    _after(gm, at + _spring_duration(_drop_preset), function()
        if not fx or fx.REMOVED or not (fx.config and fx.config.pendulum_string) then return Y end
        return _ease(gm, fx.config.pendulum_string, "alpha", 0, _string_time*_dilation(_drop_preset))
    end)
    _after(gm, at + _spring_duration(_drop_preset) + _string_time*_dilation(_drop_preset), function() _clear_string(fx); return Y end)
end

--- Helper: realign
function M.realign(gm, fx)
    if not fx then return end
    _ease(gm, fx, "draw_offset_x", 0, _realign_time*_time_dilation)
    _ease(gm, fx, "draw_offset_y", 0, _realign_time*_time_dilation)
    _ease(gm, fx, "draw_rotate", 0, _realign_time*_time_dilation)
end

return M
