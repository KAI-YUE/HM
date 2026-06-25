local Motion     = require("HMEng.ui_actors.common.motion")
local PhysicsMotion = require("HMEng.ui_actors.common.physics_motion")
local Tree       = require("HMEng.ui_actors.common.tree")
local AnimUtils  = require("HMfns.animate.transitions.anim_utils")

local rand = math.random

local Y = true

local M = {}

local _arrow_start            = 0.2
local _arrow_gap              = 0.2
local _arrow_fade_time        = 0.1
local _arrow_fade_dilation    = 1
local _arrow_pendulum_step    = 1/120
local _arrow_settle_time      = 0.58

local _queue                = "save_menu_enter"
local _cache_draw_offset    = Motion.cache_draw_offset
local _restore_draw_offset  = Motion.restore_draw_offset

--- Helper: _after | _ease
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end
local function _ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _queue) end

--- Helper: _normal_draw_alpha
local function _normal_draw_alpha(widget) return widget and (widget.page_switch_draw_alpha or widget.draw_alpha) end

-- length: string radius;    theta: starting angle; 
-- freq: swing speed;        damp: settle speed; 
-- side_pull: slight non-pendulum lateral drift.
-- settle_time: optional final ease-to-slot duration; defaults to _arrow_settle_time.
local _arrow_enter = {   
    save_page_prev = { pendulum = { duration = 5.35 + rand(), length = 6 + 2*rand(),  theta = -1.04, freq = 2.1 + rand() , damp = 0.45 + 0.5*rand(),  side_pull = -0.08 + 0.1*rand() } },
    save_page_next = { pendulum = { duration = 5.22 + rand(), length = 10 + 5*rand(), theta = -0.98, freq = 2.55 + rand(), damp = 0.45 + 0.5*rand(), side_pull =  0.08 + 0.1*rand() } },
}

local _slide_bar_enter = { delay = 2.1, fade_only = Y, fade_time = 1 }
local _enter_order = {
    { id = "save_page_next",      preset = _arrow_enter.save_page_next },
    { id = "save_page_slide_bar", preset = _slide_bar_enter },
    { id = "save_page_prev",      preset = _arrow_enter.save_page_prev },
}

--- Helper: _wander
local function _wander(value, amount)
    local rand = math.random()
    return value*(1 + (rand*2 - 1)*(amount or 0))
end

--- Helper: _cache_arrow_enter
local function _cache_arrow_enter(arrow)
    if not arrow or arrow._save_menu_arrow_enter_cached then return end
    arrow._save_menu_arrow_enter = {
        draw_alpha      = _normal_draw_alpha(arrow),
        pendulum_string = arrow.config and arrow.config.pendulum_string,
    }
    arrow._save_menu_arrow_enter_cached = Y
end

--- Helper: _restore_arrow_enter
local function _restore_arrow_enter(arrow)
    local normal = arrow and arrow._save_menu_arrow_enter
    if not normal then return Y end
    arrow.draw_alpha = normal.draw_alpha
    if arrow.config then arrow.config.pendulum_string = normal.pendulum_string end
    arrow._save_menu_arrow_enter = nil
    arrow._save_menu_arrow_enter_cached = nil
    return Y
end

--- Helper: _string_alpha
local function _string_alpha(progress) if progress <= 0 or progress >= 1 then return 0 end; return 0.5*math.min(1, progress/0.12)*(1 - progress)^0.85 end

--- Helper: _set_pendulum_frame
local function _set_pendulum_frame(widget, normal, pendulum, t)
    if widget.REMOVED then return Y end

    local offset = PhysicsMotion.damped_pendulum_offset(pendulum, t)
    widget.draw_offset_x, widget.draw_offset_y = normal.x + offset.x, normal.y + offset.y
    if widget.config then
        widget.config.pendulum_string = {
            alpha = _string_alpha(t/(pendulum.duration or 1)),
            pivot = { x = 0, y = -(pendulum.length or 3.5) },
            color = { 1, 1, 1, 0.72 },
            width = 0.01,
        }
    end
    return Y
end

--- Helper: _settle_pendulum_offset
local function _settle_pendulum_offset(gm, widget, normal, settle_time)
    if widget.REMOVED then return Y end
    if widget.config and widget.config.pendulum_string then _ease(gm, widget.config.pendulum_string, "alpha", 0, settle_time, "sine") end
    _ease(gm, widget, "draw_offset_x", normal.x, settle_time, "sine")
    return _ease(gm, widget, "draw_offset_y", normal.y, settle_time, "sine")
end

--- Helper: _pendulum_draw_offset
local function _pendulum_draw_offset(gm, widget, key, pendulum, delay)
    if not (widget and pendulum) then return end

    _cache_draw_offset(widget, key)
    local normal      = widget[key]
    local duration    = pendulum.duration or 2.2
    local settle_time = pendulum.settle_time or _arrow_settle_time
    local swing_time  = math.max(0, duration - settle_time)
    local steps       = math.ceil(swing_time/_arrow_pendulum_step)

    _set_pendulum_frame(widget, normal, pendulum, 0)
    for i = 1, steps do
        local frame_t = math.min(swing_time, i*_arrow_pendulum_step)
        _after(gm, (delay or 0) + frame_t, function() return _set_pendulum_frame(widget, normal, pendulum, frame_t) end)
    end

    _after(gm, (delay or 0) + swing_time, function() return _settle_pendulum_offset(gm, widget, normal, settle_time) end)
    _after(gm, (delay or 0) + duration + 0.04, function()
        if widget.config then widget.config.pendulum_string = nil end
        return _restore_draw_offset(widget, key)
    end)
    return (delay or 0) + duration + 0.04
end

--- Helper: _set_enter_draw_alpha
local function _set_enter_draw_alpha(widget)
    if not widget then return end
    _cache_arrow_enter(widget)
    widget.draw_alpha = 0
end

--- Helper: _fade_in_arrow_part
local function _fade_in_arrow_part(gm, widget, preset, delay)
    if not (widget and preset) then return end

    local normal = widget._save_menu_arrow_enter
    local motion_delay = delay + (preset.delay or 0) + _wander(0.04, 1)

    if preset.fade_only then
        _after(gm, motion_delay, function()
            if widget.REMOVED then return Y end
            _ease(gm, widget, "draw_alpha", normal.draw_alpha or 1, (preset.fade_time or _arrow_fade_time)*_arrow_fade_dilation, "lerp")
            return Y
        end)
        _after(gm, motion_delay + (preset.fade_time or _arrow_fade_time)*_arrow_fade_dilation + 0.04, function() return _restore_arrow_enter(widget) end)
        return
    end

    local pendulum = preset.pendulum
    local pendulum_done = _pendulum_draw_offset(gm, widget, "_save_menu_arrow_offset_enter", pendulum, motion_delay)

    _after(gm, motion_delay, function()
        if widget.REMOVED then return Y end
        _ease(gm, widget, "draw_alpha", normal.draw_alpha or 1, _arrow_fade_time*_arrow_fade_dilation, "lerp")
        return Y
    end)
    _after(gm, pendulum_done, function() return _restore_arrow_enter(widget) end)
end

--- Helper: fade_in
function M.fade_in(gm, root)
    for _, enter in ipairs(_enter_order) do _set_enter_draw_alpha(Tree.find_child_by_id(root, enter.id)) end
    for i, enter in ipairs(_enter_order) do _fade_in_arrow_part(gm, Tree.find_child_by_id(root, enter.id), enter.preset, _arrow_start + _arrow_gap*(i - 1)) end
end

return M
