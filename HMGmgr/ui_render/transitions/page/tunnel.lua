local ShaderUtils    = require("HMEng.visual.shader_utils")
local PageTunnel     = require("HMui.menu.transitions.page.tunnel")
local TransitionCommon = require("HMGmgr.ui_render.transitions.common")

local send_base_uniforms = ShaderUtils.send_base_uniforms
local send_sp_uniform    = ShaderUtils.send_sp_uniform
local opt_value          = TransitionCommon.opt_value

local LG = love.graphics
local Y, N = true, false
local cw = require("HMfns.animate.color.color_const").WHITE

local M = {}

-----------------------------
--- _draw_page_tunnel_transition
----------------------------------
--- Helper: shader_seed
local function shader_seed(trans)
    return opt_value(trans.shader_seed, opt_value(trans.shader_salt, 0))
end

--- Helper: _send_page_tunnel_uniforms
function M._send_page_tunnel_uniforms(gm, shader, trans, canvas, progress)
    if shader:hasUniform("texel_size") then shader:send("texel_size", { 1 / canvas:getWidth(), 1 / canvas:getHeight() }) end
    if shader:hasUniform("time") then shader:send("time", gm._T and gm._T.session_s or 0) end
    if shader:hasUniform("progress") then shader:send("progress", progress) end
    if shader:hasUniform("tunnel_tone_light") then shader:send("tunnel_tone_light", trans.tunnel_tone_light or { 1, 1, 1, 1 }) end
    if shader:hasUniform("tunnel_tone_mid") then shader:send("tunnel_tone_mid", trans.tunnel_tone_mid or { 1, 1, 1, 1 }) end
    if shader:hasUniform("tunnel_tone_accent") then shader:send("tunnel_tone_accent", trans.tunnel_tone_accent or { 1, 1, 1, 1 }) end
    if shader:hasUniform("quick_pass") then shader:send("quick_pass", trans.quick_pass and 1 or 0) end
    if shader:hasUniform("phases") then shader:send("phases", trans.phases or { 0.45, 0.14, 0.41 }) end
    if shader:hasUniform("brush_wobble") then shader:send("brush_wobble", opt_value(trans.brush_wobble, 1.0)) end
    if shader:hasUniform("brush_bleed") then shader:send("brush_bleed", opt_value(trans.brush_bleed, 1.0)) end
    if shader:hasUniform("brush_stroke_width") then shader:send("brush_stroke_width", opt_value(trans.brush_stroke_width, 1.0)) end
    if shader:hasUniform("brush_cover_start") then shader:send("brush_cover_start", opt_value(trans.brush_cover_start, 0.74)) end
    if shader:hasUniform("brush_cover_end") then shader:send("brush_cover_end", opt_value(trans.brush_cover_end, 1.0)) end
    if shader:hasUniform("generic") then shader:send("generic", { 0, gm._T and gm._T.real_s or 0, shader_seed(trans) }) end
    if shader:hasUniform("cover_wipe_pass") then shader:send("cover_wipe_pass", 0) end
end

--- Helper: _send_page_tunnel_hold_filter_uniforms
function M._send_page_tunnel_hold_filter_uniforms(gm, shader, trans, canvas)
    if shader:hasUniform("texel_size") then shader:send("texel_size", { 1 / canvas:getWidth(), 1 / canvas:getHeight() }) end
    if shader:hasUniform("blur_radius") then shader:send("blur_radius", trans.hold_filter_blur_radius or 5.0) end
    if shader:hasUniform("dim_color") then shader:send("dim_color", trans.hold_filter_dim_color or { 0, 0, 0, 0 }) end
    if shader:hasUniform("time") then shader:send("time", trans.hold_filter_shader_time or trans.start_s or 0) end
end

--- Helper: _lock_page_tunnel_transition
function M._lock_page_tunnel_transition(gm)
    local Ctrl = gm.CTRL; if not (Ctrl and Ctrl.locks) then return end
    Ctrl.locks.page_tunnel_transition = Y
    Ctrl.locks.frame = Y
    if Ctrl.cursor_down then Ctrl.cursor_down.target = nil end
end

--- Helper: _clear_page_tunnel_transition
function M._clear_page_tunnel_transition(gm)
    local trans = gm.page_tunnel_transition
    gm.page_tunnel_transition = nil
    if trans and type(trans.on_revealed) == "function" then trans.on_revealed(gm, trans) end
    local Ctrl = gm.CTRL; if not (Ctrl and Ctrl.locks) then return Y end
    Ctrl.locks.page_tunnel_transition = nil
    if not Ctrl.locks.frame_set and not Ctrl.locks.page_animator_transition then Ctrl.locks.frame = nil end
    return Y
end

--- Helper: _page_tunnel_cover_point
function M._page_tunnel_cover_point(trans)
    local phases = trans.phases or { 0.45, 0.14, 0.41 }
    if trans.hold_filter_shader then return phases[1] or 0.45 end
    return (phases[1] or 0.45) + (phases[2] or 0.14) * 0.5
end

--- Helper: _maybe_fire_page_tunnel_cover
function M._maybe_fire_page_tunnel_cover(gm, trans, progress)
    if trans.covered or progress < M._page_tunnel_cover_point(trans) then return end
    trans.covered = Y
    local fn = trans.on_covered; if type(fn) ~= "function" then return end
    return fn(gm, trans)
end

--- Helper: _page_tunnel_fade_out_start
function M._page_tunnel_fade_out_start(trans)
    local phases = trans and trans.phases or { 0.45, 0.14, 0.41 }
    return (phases[1] or 0.45) + (phases[2] or 0.14)
end

--- Helper: _maybe_start_page_tunnel_reveal
function M._maybe_start_page_tunnel_reveal(gm, trans, progress)
    if not trans.covered or trans.reveal_started or progress < M._page_tunnel_fade_out_start(trans) then return end
    return PageTunnel.reveal_new_page(gm, trans)
end

--- Helper: _page_tunnel_progress
function M._page_tunnel_progress(gm, trans)
    if not trans then return 1 end
    local now = gm._T and gm._T.session_s or 0
    local duration = trans.duration or 1.08
    local dilation = trans.time_dilation or 1
    return duration > 0 and math.min(1, (now - (trans.start_s or now)) / (duration * dilation)) or 1
end

--- Helper: _page_tunnel_hides_scene
function M._page_tunnel_hides_scene(gm)
    local trans = gm.page_tunnel_transition; if not trans then return N end
    local progress = M._page_tunnel_progress(gm, trans)
    M._maybe_fire_page_tunnel_cover(gm, trans, progress)
    local hides = trans.covered and progress < M._page_tunnel_fade_out_start(trans)
    if trans.covered and not hides then M._maybe_start_page_tunnel_reveal(gm, trans, progress) end
    return hides
end

--- Helper: _page_tunnel_renders_hold_scene
function M._page_tunnel_renders_hold_scene(gm)
    local trans = gm.page_tunnel_transition
    return trans and trans.covered and trans.render_scene_during_hold ~= N
end

--- Helper: _ensure_page_tunnel_hold_filter
function M._ensure_page_tunnel_hold_filter(gm, trans, brush_shader)
    if not (trans and trans.canvas and trans.hold_filter_shader) then return N end
    if trans.hold_filter_canvas then return Y end

    local src = trans.canvas
    local w, h = src:getWidth(), src:getHeight()
    local brush_canvas = LG.newCanvas(w, h)
    local filter_canvas = LG.newCanvas(w, h)
    local filter_shader = gm.t_shaders and gm.t_shaders[trans.hold_filter_shader]
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    local r, g, b, a = LG.getColor()
    local capture_progress = trans.phases and trans.phases[1] or 0.45

    LG.push()
    LG.origin()
    LG.setCanvas({ brush_canvas, stencil = Y })
    LG.clear(0, 0, 0, 0)
    LG.setColor(cw)
    LG.setShader()
    LG.draw(src, 0, 0)
    if brush_shader then
        M._send_page_tunnel_uniforms(gm, brush_shader, trans, src, capture_progress)
        LG.setShader(brush_shader)
    else
        LG.setShader()
    end
    LG.draw(src, 0, 0)

    LG.setCanvas({ filter_canvas, stencil = Y })
    LG.clear(0, 0, 0, 0)
    if filter_shader then
        M._send_page_tunnel_hold_filter_uniforms(gm, filter_shader, trans, brush_canvas)
        LG.setShader(filter_shader)
    else
        LG.setShader()
    end
    LG.draw(brush_canvas, 0, 0)
    LG.pop()

    if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end
    LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    trans.hold_filter_canvas = filter_canvas
    return Y
end

--- Helper: _draw_page_tunnel_hold_filter
function M._draw_page_tunnel_hold_filter(gm, trans)
    local canvas = trans and trans.hold_filter_canvas; if not canvas then return N end
    local old_shader = LG.getShader()
    LG.push()
    LG.origin()
    LG.setShader()
    LG.setColor(cw)
    LG.draw(canvas, 0, 0)
    LG.setShader(old_shader)
    LG.pop()
    return Y
end

--- Helper: _ensure_page_tunnel_cover_wipe
function M._ensure_page_tunnel_cover_wipe(gm, trans, progress, shader)
    if not (trans and trans.cover_wipe ~= N and trans.canvas) then return N end
    if trans.cover_wipe_canvas then return Y end
    if trans.hold_filter_canvas then trans.cover_wipe_canvas = trans.hold_filter_canvas; return Y end

    local src = trans.canvas
    local w, h = src:getWidth(), src:getHeight()
    local canvas = LG.newCanvas(w, h)
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    local r, g, b, a = LG.getColor()
    local capture_progress = M._page_tunnel_fade_out_start(trans)

    LG.push()
    LG.origin()
    LG.setCanvas({ canvas, stencil = Y })
    LG.clear(0, 0, 0, 0)
    LG.setColor(cw)
    if shader then
        M._send_page_tunnel_uniforms(gm, shader, trans, src, capture_progress)
        LG.setShader(shader)
    else
        LG.setShader()
    end
    LG.draw(src, 0, 0)
    LG.pop()

    if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end
    LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    trans.cover_wipe_canvas = canvas
    return Y
end

--- Helper: _draw_page_tunnel_cover_wipe
function M._draw_page_tunnel_cover_wipe(gm, trans, progress)
    local canvas = trans and trans.cover_wipe_canvas; if not canvas then return N end
    local shader_name = trans.shader or "brush_scribble"
    local shader = gm.t_shaders and gm.t_shaders[shader_name]
    local old_shader = LG.getShader()
    local w, h = canvas:getWidth(), canvas:getHeight()
    local wipe_p = PageTunnel.cover_wipe_progress(trans, progress)
    local tex_details, image_details, wipe_rect = TransitionCommon.load_snapshot_mask_domain(gm, { fx_mask_ref = "room" }, w, h)

    LG.push()
    LG.origin()
    LG.setColor(cw)
    if shader then
        send_base_uniforms(shader, {
            fx_mask = wipe_p,
            time = gm._T and gm._T.real_s or 0,
            tex_details = tex_details,
            image_details = image_details,
            shadow = N,
        })
        send_sp_uniform(shader, "fx_mask_dir", trans.cover_wipe_dir or 0)
        send_sp_uniform(shader, "fx_mask_seed", trans.cover_wipe_seed or 0)
        send_sp_uniform(shader, "brush_wobble", opt_value(trans.brush_wobble, 1.0))
        send_sp_uniform(shader, "brush_bleed", opt_value(trans.brush_bleed, 1.0))
        send_sp_uniform(shader, "brush_stroke_width", opt_value(trans.brush_stroke_width, 1.0))
        send_sp_uniform(shader, "wipe_rect", wipe_rect)
        send_sp_uniform(shader, "generic", { 0, gm._T and gm._T.real_s or 0, shader_seed(trans) + (trans.cover_wipe_seed or 0) })
        send_sp_uniform(shader, "cover_wipe_pass", 1)
        LG.setShader(shader)
    else
        LG.setShader()
    end
    LG.draw(canvas, 0, 0)
    send_sp_uniform(shader, "cover_wipe_pass", 0)
    LG.setShader(old_shader)
    LG.pop()
    return Y
end

--- Helper: _draw_page_tunnel_transition
function M._draw_page_tunnel_transition(gm)
    local trans = gm.page_tunnel_transition
    local canvas = trans and trans.canvas; if not canvas then return N end

    local progress = M._page_tunnel_progress(gm, trans)
    local shader = gm.t_shaders and gm.t_shaders[trans.shader or "_page_tunnel"]
    local old_shader = LG.getShader()

    M._lock_page_tunnel_transition(gm)
    M._maybe_fire_page_tunnel_cover(gm, trans, progress)
    M._maybe_start_page_tunnel_reveal(gm, trans, progress)

    if progress >= (trans.phases and trans.phases[1] or 0.45) then
        M._ensure_page_tunnel_hold_filter(gm, trans, shader)
    end

    if trans.cover_wipe ~= N and progress >= M._page_tunnel_fade_out_start(trans) then
        M._ensure_page_tunnel_cover_wipe(gm, trans, progress, shader)
        M._draw_page_tunnel_cover_wipe(gm, trans, progress)
        if progress >= 1 then M._clear_page_tunnel_transition(gm) end
        return Y
    end

    if trans.hold_filter_canvas and progress >= (trans.phases and trans.phases[1] or 0.45) then
        M._draw_page_tunnel_hold_filter(gm, trans)
        if progress >= 1 then M._clear_page_tunnel_transition(gm) end
        return Y
    end

    LG.push()
    LG.origin()
    LG.setColor(cw)
    if shader then
        M._send_page_tunnel_uniforms(gm, shader, trans, canvas, progress)
        LG.setShader(shader)
    else
        LG.setShader()
    end
    LG.draw(canvas, 0, 0)
    LG.setShader(old_shader)
    LG.pop()

    if progress >= 1 then M._clear_page_tunnel_transition(gm) end
    return Y
end

return M
