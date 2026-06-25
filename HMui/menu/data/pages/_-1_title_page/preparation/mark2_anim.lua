local Common = require("HMui.menu.data.pages._-1_title_page.anims.common")

local _after  = Common.after
local rand    = math.random

local Y, N = true, false

local M = {}

local _key = "_press_any_mark2_cursor"
local _id  = "press_any_underline_mark2"
local _mark1_id = "press_any_underline_mark1"

local cfg = {
    start_alpha = 0,        peak_alpha   = 1,
    underline_w = 4.55,     base_bias    = -2.18,
    
    start_prop  = 0.42,     end_prop     = 0.62,
    start_x     = nil,      end_x        = nil,

    --- time settings 
    mark2_travel_t    = 3.05,
    mark2_fade_in_t   = 0.28,        mark2_fade_out_at  = 0.68,
    mark1_fade_in_at  = 0.40,  mark1_fade_in_t  = 3.05,
    mark1_hold_min    = 2.,  mark1_hold_max   = 2.33,
    mark1_fade_out_t  = 0.7,
    
    ease        = "sine",
}

--- Helper: _bias_at
local function _bias_at(prop) return (prop - 0.5)*cfg.underline_w end

--- Helper: _travel
local function _travel()
    local start_x = cfg.start_x or (_bias_at(cfg.start_prop) - cfg.base_bias)
    local end_x   = cfg.end_x   or (_bias_at(cfg.end_prop)   - cfg.base_bias)
    return start_x, end_x
end

--- Helper: _mark1_hold_time
local function _mark1_hold_time() return cfg.mark1_hold_min + rand()*(cfg.mark1_hold_max - cfg.mark1_hold_min) end

--- Helper: _ease
local function _ease(gm, widget, key, to, delay, ease)
    if not (gm and gm.E_MANAGER) then widget[key] = to; return Y end
    gm.E_MANAGER:enqueue_event({ queue = Common.queue, trigger = "ease", ease = ease or cfg.ease, blockable = N, blocking = N, ref_table = widget, ref_value = key, ease_to = to, delay = delay })
    return Y
end

--- Helper: _mark1_alive
local function _mark1_alive(mark1, token) return mark1 and not mark1.REMOVED and mark1[_key .. "_token"] == token end

--- Helper: _run_cycle
local function _run_cycle(gm, widget, mark1, token)
    if not widget or widget.REMOVED or widget[_key .. "_token"] ~= token then return Y end

    local normal = widget[_key .. "_offset"];                    if not normal then return Y end

    local start_x, end_x = _travel()
    widget.draw_offset_x = normal.x + start_x
    widget.draw_offset_y = normal.y
    widget.draw_alpha    = cfg.start_alpha

    _ease(gm, widget, "draw_offset_x", normal.x + end_x, cfg.mark2_travel_t, cfg.ease)
    _ease(gm, widget, "draw_alpha",    cfg.peak_alpha, cfg.mark2_fade_in_t, cfg.ease)
    
    if _mark1_alive(mark1, token) then mark1.draw_alpha = cfg.start_alpha end
    _after(gm, cfg.mark1_fade_in_at, function()
        if _mark1_alive(mark1, token) then _ease(gm, mark1, "draw_alpha", cfg.peak_alpha, cfg.mark1_fade_in_t, cfg.ease) end
        return Y
    end)

    _after(gm, cfg.mark2_fade_out_at, function()
        if widget.REMOVED or widget[_key .. "_token"] ~= token then return Y end
        return _ease(gm, widget, "draw_alpha", cfg.start_alpha, math.max(0.05, cfg.mark2_travel_t - cfg.mark2_fade_out_at), cfg.ease)
    end)

    local mark1_fade_at = cfg.mark1_fade_in_at + cfg.mark1_fade_in_t + _mark1_hold_time()
    local cycle_t       = mark1_fade_at + cfg.mark1_fade_out_t

    _after(gm, mark1_fade_at, function()
        if _mark1_alive(mark1, token) then _ease(gm, mark1, "draw_alpha", cfg.start_alpha, cfg.mark1_fade_out_t, cfg.ease) end
        return Y
    end)
    _after(gm, cycle_t, function() return _run_cycle(gm, widget, mark1, token) end)
    return Y
end

----------------------------------------------
--- main: start
----------------------------------------------
function M.start(gm, root)
    local widget = Common.find(root, _id);        if not widget then return end
    local mark1  = Common.find(root, _mark1_id)
    
    Common.cache_widget(widget, _key)
    if mark1 then Common.cache_widget(mark1, _key) end
    
    widget[_key .. "_token"] = (widget[_key .. "_token"] or 0) + 1
    if mark1 then mark1[_key .. "_token"] = widget[_key .. "_token"] end
    return _run_cycle(gm, widget, mark1, widget[_key .. "_token"])
end

return M
