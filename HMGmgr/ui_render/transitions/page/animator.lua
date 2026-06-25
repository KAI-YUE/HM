local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")
local PageAnimator  = require("HMui.menu.transitions.page.animator")
local ShaderUtils   = require("HMEng.visual.shader_utils")
local TransitionCommon = require("HMGmgr.ui_render.transitions.common")

local LG = love.graphics

local min, max = math.min, math.max
local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_sp_uniform    = ShaderUtils.send_sp_uniform
local load_snapshot_mask_domain = TransitionCommon.load_snapshot_mask_domain

local Y, N = true, false

local M = {}

-----------------------------
--- _draw_page_animator_transition
----------------------------------
--- Helper: clamp01
local function clamp01(v) return min(1, max(0, v or 0)) end

--- Helper: lerp
local function lerp(a, b, p) return (a or 0) + ((b or 0) - (a or 0)) * p end

--- Helper: smoothstep
local function smoothstep(v) v = clamp01(v); return v * v * (3 - 2 * v) end

--- Helper: screen_rect_to_tiles
local function screen_rect_to_tiles(gm, trans, dims)
    local rcfg = gm.rcfg or {}
    local tile_w, tile_h = rcfg.tile_w or 0, rcfg.tile_h or 0
    local w, h = trans.w, trans.h
    local x, y = trans.x or 0.5, trans.y or 0.5
    local ratio = max(dims and dims.w or 1, 1) / max(dims and dims.h or 1, 1)

    if trans.fit_axis == "width" then
        w = w or 3.8
        h = w / ratio
    elseif trans.fit_axis == "height" then
        h = h or 3.8
        w = h * ratio
    end
    w, h = w or 3.8, h or w or 3.8

    if trans.anchor == "screen" then
        x = x <= 1 and x * tile_w or x
        y = y <= 1 and y * tile_h or y
        x, y = x - w * 0.5, y - h * 0.5
    end

    return x, y, w, h
end

--- Helper: delayed_alpha
local function delayed_alpha(gm, trans)
    if trans.alpha_delay == nil then return 1 end
    local now = gm._T and gm._T.session_s or 0
    local elapsed = now - (trans.start_s or now)
    local delay = trans.alpha_delay or 0
    local duration = trans.alpha_fade_duration or 0
    if elapsed <= delay then return 0 end
    if duration <= 0 then return 1 end
    return smoothstep((elapsed - delay) / duration)
end

--- Helper: delayed_zoom_progress
local function delayed_zoom_progress(gm, trans)
    local now = gm._T and gm._T.session_s or 0
    local elapsed = now - (trans.start_s or now)
    local delay = trans.zoom_delay or 0
    local duration = trans.zoom_duration or trans.duration or 1
    local dilation = trans.time_dilation or 1
    if elapsed <= delay then return 0 end
    return clamp01((elapsed - delay) / max(duration * dilation, 0.001))
end

--- Helper: delayed_offset_progress
local function delayed_offset_progress(gm, trans)
    local now = gm._T and gm._T.session_s or 0
    local elapsed = now - (trans.start_s or now)
    local delay = trans.offset_delay or 0
    local duration = trans.offset_duration or trans.zoom_duration or trans.duration or 1
    local dilation = trans.time_dilation or 1
    if elapsed <= delay then return 0 end
    return clamp01((elapsed - delay) / max(duration * dilation, 0.001))
end

--- Helper: visual_motion_complete
local function visual_motion_complete(gm, trans)
    return delayed_zoom_progress(gm, trans) >= 1 and delayed_offset_progress(gm, trans) >= 1
end

-----------------------------
--- transition state
----------------------------------
--- Helper: _page_animator_param_progress
function M._page_animator_param_progress(gm, trans)
    if not trans then return 1 end
    local now = gm._T and gm._T.session_s or 0
    local duration = trans.duration or 1
    local dilation = trans.time_dilation or 1
    return duration > 0 and clamp01((now - (trans.start_s or now)) / (duration * dilation)) or 1
end

--- Helper: _page_animator_progress
function M._page_animator_progress(gm, trans)
    if not trans then return 1 end
    local now = gm._T and gm._T.session_s or 0
    local elapsed = now - (trans.start_s or now)
    local dilation = trans.time_dilation or 1
    local param_duration = (trans.duration or 1) * dilation
    local zoom_duration = (trans.zoom_delay or 0) + (trans.zoom_duration or trans.duration or 1) * dilation
    local offset_duration = (trans.offset_delay or 0) + (trans.offset_duration or trans.zoom_duration or trans.duration or 1) * dilation
    local duration = max(param_duration, zoom_duration, offset_duration)
    return duration > 0 and clamp01(elapsed / duration) or 1
end

--- Helper: _page_animator_wipe_progress
function M._page_animator_wipe_progress(gm, trans)
    if not trans then return 1 end
    local now = gm._T and gm._T.session_s or 0
    local duration = trans.wipe_duration or 0.58
    local dilation = trans.time_dilation or 1
    return duration > 0 and clamp01((now - (trans.wipe_start_s or now)) / (duration * dilation)) or 1
end

--- Helper: _lock_page_animator_transition
function M._lock_page_animator_transition(gm)
    local Ctrl = gm.CTRL; if not (Ctrl and Ctrl.locks) then return end
    Ctrl.locks.page_animator_transition = Y
    Ctrl.locks.frame = Y
    if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end
end

--- Helper: _clear_page_animator_transition
function M._clear_page_animator_transition(gm)
    local trans = gm.page_animator_transition
    gm.page_animator_transition = nil
    M._release_page_animator_actor(gm, trans)
    if trans and type(trans.on_revealed) == "function" then trans.on_revealed(gm, trans) end
    return PageAnimator.clear(gm, trans)
end

--- Helper: _maybe_fire_page_animator_cover
function M._maybe_fire_page_animator_cover(gm, trans, progress)
    if trans.covered or progress < (trans.cover_point or 0.5) then return end
    trans.covered = Y
    local fn = trans.on_covered
    if type(fn) ~= "function" then trans.ready_to_reveal = Y; return end
    local ret = fn(gm, trans)
    if trans.wait_for_ready == N then trans.ready_to_reveal = Y end
    return ret
end

--- Helper: _page_animator_hides_scene
function M._page_animator_hides_scene(gm)
    local trans = gm.page_animator_transition; if not trans then return N end
    if trans.bg_transition and gm.page_tunnel_transition == trans.bg_transition then return N end
    if trans.wiping or trans.ready_to_reveal then return N end
    local progress = M._page_animator_progress(gm, trans)
    M._maybe_fire_page_animator_cover(gm, trans, progress)
    if trans.ready_to_reveal then return N end
    return trans.hide_scene ~= N
end

-----------------------------
--- actor helpers
----------------------------------
--- Helper: _new_page_animator_actor
local function _new_page_animator_actor(gm, trans)
    if not trans.model_def then return end

    return AnimDecorator(gm, 0, 0, trans.w or 3.8, trans.h or 3.8, {
        model_def    = trans.model_def,
        model_json   = trans.model_json,
        path         = trans.path,
        motion_group = trans.motion_group,
        auto_update  = N,
        can_collide  = N,
        can_hover    = N,
        can_click    = N,
        can_drag     = N,
        draw_alpha   = trans.alpha_from or 1,
        scale_x      = trans.scale_x or 1,
        scale_y      = trans.scale_y or 1,
        T = { r = trans.r or 0, scale = trans.zoom_from or 1 },
    })
end

--- Helper: _preload_page_animator_actor
function M._preload_page_animator_actor(gm, trans)
    local cached = gm.page_animator_actor_cache
    if cached and not cached.REMOVED and cached.model_def == trans.model_def then return cached end
    if cached and not cached.REMOVED and cached.remove then cached:remove() end

    local actor = _new_page_animator_actor(gm, trans); if not actor then return end
    actor.states.visible = N
    gm.page_animator_actor_cache = actor
    gm.page_animator_actor_in_use = nil
    return actor
end

--- Helper: _release_page_animator_actor
function M._release_page_animator_actor(gm, trans)
    local actor = trans and trans.actor; if not actor then return end
    trans.actor = nil

    if actor == gm.page_animator_actor_cache and not actor.REMOVED then
        actor.states.visible = N
        gm.page_animator_actor_in_use = nil
        return actor
    end
    if actor.remove and not actor.REMOVED then actor:remove() end
end

--- Helper: _ensure_page_animator_actor
function M._ensure_page_animator_actor(gm, trans)
    if trans.actor then return trans.actor end
    if not trans.model_def then return end

    local cached = gm.page_animator_actor_cache
    local actor
    if cached and not cached.REMOVED and not gm.page_animator_actor_in_use and cached.model_def == trans.model_def then
        actor = cached
        gm.page_animator_actor_in_use = Y
    else
        actor = _new_page_animator_actor(gm, trans)
    end
    if not actor then return end

    actor.states.visible = Y
    actor.draw_alpha = trans.alpha_from or 1
    actor.draw_offset_x, actor.draw_offset_y = trans.x_offset_from or 0, trans.y_offset_from or 0
    actor.model_scale.x, actor.model_scale.y = trans.scale_x or 1, trans.scale_y or 1
    actor.T.r, actor.VT.r = trans.r or 0, trans.r or 0
    actor.T.scale, actor.VT.scale = trans.zoom_from or 1, trans.zoom_from or 1
    local x, y, w, h = screen_rect_to_tiles(gm, trans, actor.model_dims)
    actor:hard_set_T(x, y, w, h)

    trans.actor = actor
    return actor
end

--- Helper: _update_page_animator_actor
local function _update_page_animator_actor(gm, trans, actor, progress)
    local p = smoothstep(progress)
    local zoom_p = smoothstep(delayed_zoom_progress(gm, trans))
    local offset_p = smoothstep(delayed_offset_progress(gm, trans))
    local now = gm._T and gm._T.session_s or 0
    local dt = min(max(now - (trans.last_update_s or now), 0), 0.05)
    trans.last_update_s = now

    actor.draw_alpha = lerp(trans.alpha_from or 1, trans.alpha_to or 1, p) * delayed_alpha(gm, trans)
    actor.draw_scale_x, actor.draw_scale_y = lerp(trans.zoom_from or 1, trans.zoom_to or 1, zoom_p), lerp(trans.zoom_from or 1, trans.zoom_to or 1, zoom_p)
    actor.draw_offset_x = lerp(trans.x_offset_from or 0, trans.x_offset_to or 0, offset_p)
    actor.draw_offset_y = lerp(trans.y_offset_from or 0, trans.y_offset_to or 0, offset_p)
    if actor.set_param and trans.param_id then actor:set_param(trans.param_id, lerp(trans.param_from or -1, trans.param_to or 1, p), trans.param_lo, trans.param_hi) end
    if actor.model and actor.model.update then actor.model:update(dt) end
end

-----------------------------
--- draw helpers
----------------------------------
--- Helper: _draw_page_animator_bg
local function _draw_page_animator_bg(gm, trans)
    local bg_trans  = trans.bg_transition
    if bg_trans and gm.page_tunnel_transition == bg_trans then return end
    local bg_canvas = trans.bg_canvas or (bg_trans and (bg_trans.hold_filter_canvas or bg_trans.cover_wipe_canvas))
    if bg_canvas then
        LG.setShader()
        LG.setColor(1, 1, 1, 1)
        LG.draw(bg_canvas, 0, 0)
        return
    end

    local c = trans.bg_color; if not c then return end
    local canvas = gm.g_canvas
    local w, h
    if canvas then w, h = canvas:getDimensions() end
    LG.setShader()
    LG.setColor(c)
    LG.rectangle("fill", 0, 0, w or LG.getWidth(), h or LG.getHeight())
end

--- Helper: _draw_page_animator_cover
local function _draw_page_animator_cover(gm, trans, actor, progress)
    LG.push()
    LG.origin()
    _draw_page_animator_bg(gm, trans)
    LG.pop()

    if actor then
        _update_page_animator_actor(gm, trans, actor, progress)
        actor:draw()
    end
end

--- Helper: _capture_page_animator_cover
local function _capture_page_animator_cover(gm, trans, actor)
    local src = gm.g_canvas; if not src then return end
    local w, h = src:getWidth(), src:getHeight()
    local canvas = LG.newCanvas(w, h)
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    local r, g, b, a = LG.getColor()

    LG.push()
    LG.origin()
    LG.setCanvas({ canvas, stencil = Y })
    LG.clear(0, 0, 0, 0)
    _draw_page_animator_bg(gm, trans)
    LG.scale(gm.rcfg and gm.rcfg.s_canvas or 1)
    if actor then
        _update_page_animator_actor(gm, trans, actor, 1)
        actor:draw()
    end
    LG.pop()

    if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end
    LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    return canvas
end

--- Helper: _ensure_page_animator_wipe
local function _ensure_page_animator_wipe(gm, trans, actor)
    if trans.wipe_canvas then return Y end
    trans.wipe_canvas = _capture_page_animator_cover(gm, trans, actor)
    trans.wipe_start_s = gm._T and gm._T.session_s or 0
    trans.wiping = Y
    return trans.wipe_canvas ~= nil
end

--- Helper: _draw_page_animator_wipe
local function _draw_page_animator_wipe(gm, trans, progress)
    local canvas = trans and trans.wipe_canvas; if not canvas then return N end
    local fade_only = trans.wipe_fade_only == Y
    local shader = not fade_only and trans.wipe_shader and gm.t_shaders and gm.t_shaders[trans.wipe_shader]
    local old_shader = LG.getShader()
    local w, h = canvas:getWidth(), canvas:getHeight()

    LG.push()
    LG.origin()
    LG.setColor(1, 1, 1, fade_only and (1 - smoothstep(progress)) or 1)
    if shader and progress > 0.001 then
        local tex_details, image_details, wipe_rect = load_snapshot_mask_domain(gm, { fx_mask_ref = trans.wipe_ref or "room" }, w, h)
        send_base_uniforms(shader, {
            fx_mask = progress,
            time = gm._T and gm._T.real_s or 0,
            tex_details = tex_details,
            image_details = image_details,
            shadow = N,
        })
        send_sp_uniform(shader, "fx_mask_dir", trans.wipe_dir or 0)
        send_sp_uniform(shader, "fx_mask_seed", trans.wipe_seed or 0)
        send_sp_uniform(shader, "wipe_rect", wipe_rect)
        send_sp_uniform(shader, "generic", { 0, gm._T and gm._T.real_s or 0, trans.generic_id or 0 })
        LG.setShader(shader)
    else
        LG.setShader()
    end
    LG.draw(canvas, 0, 0)
    LG.setShader(old_shader)
    LG.pop()
    return Y
end

--- Helper: _draw_page_animator_transition
function M._draw_page_animator_transition(gm)
    local trans = gm.page_animator_transition; if not trans then return N end
    local progress = M._page_animator_progress(gm, trans)
    local param_progress = M._page_animator_param_progress(gm, trans)
    local actor = M._ensure_page_animator_actor(gm, trans)
    local old_shader = LG.getShader()
    local r, g, b, a = LG.getColor()

    M._lock_page_animator_transition(gm)
    M._maybe_fire_page_animator_cover(gm, trans, progress)

    local bg_transition_active = trans.bg_transition and gm.page_tunnel_transition == trans.bg_transition
    if trans.ready_to_reveal and not bg_transition_active and visual_motion_complete(gm, trans) then _ensure_page_animator_wipe(gm, trans, actor) end
    if trans.wiping then
        local wipe_p = M._page_animator_wipe_progress(gm, trans)
        _draw_page_animator_wipe(gm, trans, wipe_p)
        LG.setShader(old_shader)
        LG.setColor(r, g, b, a)
        if wipe_p >= 1 then M._clear_page_animator_transition(gm) end
        return Y
    end

    _draw_page_animator_cover(gm, trans, actor, param_progress)

    LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    return Y
end

return M
