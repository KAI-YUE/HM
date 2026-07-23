local TabUtils       = require("HMfns.utils.table_utils")
local TunnelColors   = require("HMui.menu.transitions.data.page_tunnel_colors")
local Timeline       = require("HMui.menu.transitions.timeline")
local SnapshotTrans  = require("HMui.menu.transitions.snapshot")
local ChildFadeTree  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")
local PanelFadeTree  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.attached_panel.fade_tree")
local T_seeds        = require("HMui.menu.transitions.data.rolling_seeds") 

local _copy        = TabUtils.deep_copy
local min, max     = math.min, math.max
local rand         = math.random
local random_pick  = TabUtils.random_pick

local Y, N = true, false

local M = {}

local t_color = TunnelColors.default
local T_time  = Timeline.tunnel

local T_tunnel = {
    shader          = "brush_scribble",               -- post shader used for the captured old page
    duration        = T_time.duration,                -- normalized transition seconds before time_dilation
    time_dilation   = T_time.time_dilation,           -- stretches duration/progress without changing queued real-time events

    tunnel_tone_light   = t_color.tunnel_tone_light,  -- bright brush/paper tone
    tunnel_tone_mid     = t_color.tunnel_tone_mid,    -- mid brush/paper tone
    tunnel_tone_accent  = t_color.tunnel_tone_accent, -- accent brush/paper tone

    brush_wobble        = 0.4 + 0.2*rand(),           -- stroke path/edge waviness
    brush_bleed         = 0.5,                        -- wet edge spread/feather amount
    brush_stroke_width  = 0.6 + 0.2*rand(),           -- scalar applied to generated stroke widths
    brush_cover_start   = 1.0,                        -- disabled: filter is applied by hold snapshot shader
    brush_cover_end     = 1.0,                        -- disabled: filter is applied by hold snapshot shader

    hold_filter_shader       = "mc",                  -- shader applied once to the end-of-fade-in brush snapshot
    hold_filter_blur_radius  = 0.4,                   -- blur radius for hold_filter_shader

    render_scene_during_hold = Y,                     -- draw the new scene behind the opaque cover during hold
    cover_wipe               = Y,                     -- snapshot the covered frame and wipe it out after hold
    cover_wipe_dir           = 0,                     -- 0 follows brush direction; 1..3 force cardinal dirs; >4 is radians
    cover_wipe_seed          = 0,                     -- 0 uses the shader's default brush seed
    shader_seed              = nil,                   -- nil picks a tested seed from T_seeds per transition
    cover_wipe_start         = T_time.cover_wipe_start, -- fade-out progress where cover wipe starts
    cover_wipe_end           = T_time.cover_wipe_end,   -- fade-out progress where cover wipe finishes

    --- phases = { fade_in, hold, fade_out }
    phases       = T_time.phases,
}

-------------------------------------------------
--- fade_out_progress
-------------------------------------------------
function M.fade_out_progress(trans, progress)
    local phases  = trans and trans.phases or T_tunnel.phases
    local start   = (phases[1] or 0.45) + (phases[2] or 0.14)
    local dur     = phases[3]  or 0.41
    if dur <= 0 then return progress >= start and 1 or 0 end
    return min(1, max(0, (progress - start) / dur))
end

-------------------------------------------------
--- cover_wipe_progress
-------------------------------------------------
--- Helper: smoothstep
local function smoothstep(v) v = min(1, max(0, v)); return v * v * (3 - 2 * v) end
function M.cover_wipe_progress(trans, progress)
    local fade_p  = M.fade_out_progress(trans, progress)
    local start   = (trans and trans.cover_wipe_start) or T_tunnel.cover_wipe_start
    local finish  = (trans and trans.cover_wipe_end)   or T_tunnel.cover_wipe_end
    local dur     = max((finish or 1) - (start or 0), 0.001)
    return smoothstep((fade_p - (start or 0)) / dur)
end

-------------------------------------------------
--- reveal_new_page
-------------------------------------------------
--- Helper: clear_tree_reveal_state
local function clear_tree_reveal_state(widget)
    if not widget then return end
    if widget.page_tunnel_reveal_state == "being_revealed" then widget.page_tunnel_reveal_state = nil end
    widget.being_revealed = nil
    for _, child in ipairs(widget.children or {}) do clear_tree_reveal_state(child) end
end

--- Helper: schedule_clear_reveal_state
local function schedule_clear_reveal_state(gm, delay, roots)
    local EM = gm and gm.E_MANAGER;                         if not EM then return end
    EM:enqueue_event({ trigger = "after", delay = delay, blocking = N, blockable = N, no_delete = Y, func = function()
        for _, root in pairs(roots or {}) do clear_tree_reveal_state(root) end
        return Y
    end })
end

--- Helper: mark_tree_reveal_state
local function mark_tree_reveal_state(widget, state)
    if not widget then return end
    widget.page_tunnel_reveal_state = state
    widget.being_revealed = (state == "being_revealed")
    for _, child in ipairs(widget.children or {}) do mark_tree_reveal_state(child, state) end
end

---____________________________________
--- main: reveal_new_page
---____________________________________
function M.reveal_new_page(gm, trans)
    if not gm or trans.reveal_started == Y then return end

    local roots = trans.reveal_roots
    local OM    = gm.UI.overlay_menu
    if not roots and OM then roots = { OM.widget, OM.attached_panel } end
    if not roots        then return end
    if not next(roots)  then return end
    trans.reveal_started = Y

    local reveal_time = trans.reveal_time or T_time.reveal_time
    for _, root in pairs(roots) do mark_tree_reveal_state(root, "being_revealed") end
    if roots[1] then ChildFadeTree.set_tree_alpha(roots[1], 0); ChildFadeTree.fade_tree_in(roots[1], gm, reveal_time) end
    if roots[2] then PanelFadeTree.set_tree_alpha(roots[2], 0); PanelFadeTree.fade_tree_in(gm, roots[2], reveal_time) end
    schedule_clear_reveal_state(gm, reveal_time, roots)
    return Y
end

-------------------------------------------------
--- start
-------------------------------------------------
--- Helper: copy_color | copy_phases | random_shader_seed
local function copy_color(c)        if not c then return end; return { c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 0 } end
local function copy_phases(t)       t = t or T_tunnel.phases; return { t[1] or 0.45, t[2] or 0.14, t[3] or 0.41 } end
local function random_shader_seed() return random_pick(T_seeds) end

--- Helper: transition_config
local function transition_config(opts)
    local trans = {}
    for k, v in pairs(T_tunnel)   do trans[k] = _copy(v) end
    for k, v in pairs(opts or {}) do trans[k] = _copy(v) end
    trans.tunnel_tone_light  = copy_color(trans.tunnel_tone_light)
    trans.tunnel_tone_mid    = copy_color(trans.tunnel_tone_mid)
    trans.tunnel_tone_accent = copy_color(trans.tunnel_tone_accent)
    trans.phases = copy_phases(trans.phases)
    if trans.shader_seed == nil then trans.shader_seed = trans.shader_salt or random_shader_seed() end
    return trans
end

--- Helper: lock_ctrl
local function lock_ctrl(gm)
    local Ctrl   = gm.CTRL;                              if not Ctrl   then return end
    local _locks = Ctrl.locks;                           if not _locks then return end
    _locks.page_tunnel_transition, _locks.frame = Y, Y
    Ctrl.cursor_down.target = nil
end


---____________________________________
--- main: start 
---____________________________________
function M.start(gm, opts)
    opts = opts or {}
    local canvas = SnapshotTrans.capture_canvas(gm);       if not canvas then return end

    local trans = transition_config(opts)
    trans.canvas  = canvas
    trans.start_s = gm._T.session_s or 0
    gm.page_tunnel_transition = trans

    lock_ctrl(gm)
    return gm.page_tunnel_transition
end

-------------------------------------------------
--- clear
-------------------------------------------------
function M.clear(gm)
    gm.page_tunnel_transition = nil
    local Ctrl = gm.CTRL;                         if not (Ctrl and Ctrl.locks) then return Y end
    Ctrl.locks.page_tunnel_transition = nil
    if not Ctrl.locks.frame_set and not Ctrl.locks.page_animator_transition then Ctrl.locks.frame = nil end
    return Y
end

return M
