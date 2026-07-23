local TabUtils = require("HMfns.utils.table_utils")
local Timeline = require("HMui.menu.transitions.timeline")

local _copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

local _def   = "resources/textures/ui/anim/rolling_pin/rolling_pin.model3.json"
local T_time = Timeline.animator

local T_animator = {
    --- basics 
    model_def      = _def,                   param_id       = "Param",
    param_from     = -1,                     param_to       = 1,
    param_lo       = -1,                     param_hi       = 1,

    --- pos settings
    x              = .45,                    y              = .55,
    w              = 14,                     fit_axis       = "width",
    scale_x        = 1,                      scale_y        = 1,
    anchor         = "screen",

    --- time 
    duration       = T_time.duration,        wipe_duration  = T_time.wipe_duration,
    time_dilation  = T_time.time_dilation,   cover_point    = T_time.cover_point,
    wait_for_ready = Y,                   
    
    --- wipe settings
    wipe_shader    = "_-1_page_wipe",        wipe_dir       = 0,
    wipe_seed      = 0,                      wipe_ref       = "room",
    wipe_fade_only = Y,

    --- zoom settings
    zoom_from      = 1.05,                   zoom_to     = 1.96,
    zoom_delay     = T_time.zoom_delay,      zoom_duration  = T_time.zoom_duration,

    --- offset settings
    x_offset_from  = 2,                      x_offset_to    = 5.,
    y_offset_from  = 0,                      y_offset_to    = 0.3,
    offset_delay   = T_time.offset_delay,    offset_duration = T_time.offset_duration,

    alpha_from     = 1.0,                    alpha_to       = 1.0,
    alpha_fade_duration = T_time.alpha_fade_duration,

    bg_color       = { 0, 0, 0, 1 },
    hide_scene     = Y,
}

-------------------------------------------------
--- start
-------------------------------------------------
--- Helper: copy_color
local function copy_color(c) if not c then return end; return { c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0 } end

--- Helper: transition_config
local function transition_config(opts)
    local trans = {}
    for k, v in pairs(T_animator) do trans[k] = _copy(v) end
    for k, v in pairs(opts or {}) do trans[k] = _copy(v) end
    trans.bg_color = copy_color(trans.bg_color)
    return trans
end

--- Helper: lock_ctrl
local function lock_ctrl(gm)
    local Ctrl   = gm and gm.CTRL;                  if not Ctrl then return end
    local _locks = Ctrl.locks;                      if not _locks then return end
    _locks.page_animator_transition, _locks.frame = Y, Y
    if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end
end

-------------------------------------------------
--- preload
-------------------------------------------------
function M.preload(gm, opts)
    if not (gm and gm._preload_page_animator_actor) then return end
    local prev_scope = gm.registry_scope
    gm.registry_scope = "system"
    local actor = gm:_preload_page_animator_actor(transition_config(opts))
    gm.registry_scope = prev_scope
    return actor
end

---____________________________________
--- main: start
---____________________________________
function M.start(gm, opts)
    if not gm then return end

    local trans = transition_config(opts)
    trans.start_s = gm._T and gm._T.session_s or 0
    gm.page_animator_transition = trans

    lock_ctrl(gm)
    return gm.page_animator_transition
end

-------------------------------------------------
--- ready
-------------------------------------------------
function M.ready(gm, trans)
    trans = trans or (gm.page_animator_transition);     if not trans then return end
    trans.ready_to_reveal = Y
    return Y
end

-------------------------------------------------
--- clear
-------------------------------------------------
function M.clear(gm, trans)
    if not gm then return Y end
    trans = trans or gm.page_animator_transition

    if gm._release_page_animator_actor                  then gm:_release_page_animator_actor(trans)
    elseif trans and trans.actor and trans.actor.remove then trans.actor:remove() end
    if gm.page_animator_transition == trans             then gm.page_animator_transition = nil end
    
    local Ctrl    = gm.CTRL;                            if not Ctrl   then return Y end
    local _locks  = Ctrl.locks;                         if not _locks then return Y end
    _locks.page_animator_transition = nil
    if not _locks.frame_set and not _locks.page_tunnel_transition then _locks.frame = nil end
    return Y
end

return M
