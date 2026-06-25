local PhysicsMotion = require("HMEng.ui_actors.common.physics_motion")
local Common        = require("HMui.menu.data.pages._-1_title_page.anims.common")
local Timeline      = require("HMui.menu.data.pages._-1_title_page.anims.timeline")

local max, min = math.max, math.min
local sin, pi  = math.sin, math.pi
local _after   = Common.after
local _cache   = Common.cache_widget

local Y, N = true, false

local M = {}

local _cycle_key   = "_title_chopsticks_cycle"
local _cycle_token = "_title_chopsticks_cycle_token"

--- Helper: _set_pivot
local function _set_pivot(widget, x, y)
    if not widget then return end
    widget.draw_anchor_x, widget.draw_anchor_y = x or 0.5, y or 0.5
    widget._debug_pivot  = { x = widget.VT.w*widget.draw_anchor_x, y = widget.VT.h*widget.draw_anchor_y }
end

--- Helper: _chop_part
local function _chop_part(gm, widget, key, cfg, delay)
    if not widget then return end
    _cache(widget, key)
    
    local normal    = widget[key]
    local duration  = cfg.duration or 0.58
    local steps     = math.ceil(duration/Common.step)

    for i = 0, steps do
        local t = min(duration, i*Common.step)
        _after(gm, delay + t, function()
            if widget.REMOVED then return Y end
            widget.draw_rotate = normal.draw_rotate + PhysicsMotion.chop_angle(cfg, t)
            return Y
        end)
    end

    _after(gm, delay + duration + 0.02, function() return Common.restore_widget(widget, key) end)
end

--- Helper: _cycle_angle
local function _cycle_angle(cfg, active_t, angle)
    local p        = active_t/(cfg.active_duration or 1)
    local envelope = sin(pi*p)
    return angle*envelope*sin(2*pi*(cfg.chops or 2)*p)
end

--- Helper: _start_idle_cycle
local function _start_idle_cycle(gm, widgets, delay, cfg)
    local down, up = widgets.chop_down, widgets.chop_up;        if not (gm and gm.E_MANAGER and down and up) then return end

    _after(gm, delay, function()
        if down.REMOVED or up.REMOVED then return Y end

        _cache(down, _cycle_key .. "_down")
        _cache(up,   _cycle_key .. "_up")

        down[_cycle_token] = (down[_cycle_token] or 0) + 1
        local _T,           token      = gm._T,                      down[_cycle_token]
        local normal_down,  normal_up  = down[_cycle_key .. "_down"], up[_cycle_key .. "_up"]
        local cycle_length, start      = cfg.idle_duration + cfg.active_duration, _T.game_s or 0

        local function tick()
            if down.REMOVED or up.REMOVED or down[_cycle_token] ~= token then return Y end

            local elapsed   = (gm._T.game_s or start) - start
            local cycle_t   = elapsed % cycle_length
            local active_t  = cycle_t - cfg.idle_duration

            down.draw_rotate = normal_down.draw_rotate
            up.draw_rotate   = normal_up.draw_rotate
            if active_t >= 0 then
                down.draw_rotate = down.draw_rotate + _cycle_angle(cfg, active_t, cfg.down_angle)
                up.draw_rotate   = up.draw_rotate   + _cycle_angle(cfg, active_t, cfg.up_angle)
            end

            _after(gm, Common.step, tick)
            return Y
        end

        tick()
        return Y
    end)
end

---_________________________
--- main: start
---_________________________
function M.start(gm, widgets)
    local cfg = Timeline.chopsticks_cycle
    _set_pivot(widgets.chop_down, cfg.down_pivot_x, cfg.down_pivot_y)
    _set_pivot(widgets.chop_up,   cfg.up_pivot_x,   cfg.up_pivot_y)

    _chop_part(gm, widgets.chop_down,     "_title_press_chop_down", { amp = 0.18, freq = 28, damp = 4.6, duration = 0.68 }, Timeline.press_decorators.chop_down)
    _chop_part(gm, widgets.chop_up,       "_title_press_chop_up",   { amp = -0.16, freq = 26, damp = 4.4, duration = 0.68, phase = 0.2 }, Timeline.press_decorators.chop_up)
    _start_idle_cycle(gm, widgets, cfg.start_delay, cfg)
end

return M
