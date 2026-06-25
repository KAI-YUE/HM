local ChildFadeTree = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")
local PanelFadeTree = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.attached_panel.fade_tree")

local LG = love.graphics
local Y, N = true, false

local send_capture_shader_uniforms

local M = {}

-------------------------------------------------
--- Helper: capture_canvas
-------------------------------------------------
function M.capture_canvas(gm, opts)
    opts = opts or {}
    local src = gm.g_canvas;                         if not src then return end
    local w, h = src:getWidth(), src:getHeight()
    local canvas = LG.newCanvas(w, h)
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    LG.setCanvas({ canvas, stencil = Y })
    LG.origin()
    local shader = opts.snapshot_shader and gm.t_shaders and gm.t_shaders[opts.snapshot_shader]
    if shader then send_capture_shader_uniforms(gm, shader, src, opts) end
    LG.setShader(shader)
    LG.setColor(1, 1, 1, 1)
    LG.clear(0, 0, 0, 1)
    LG.draw(src, 0, 0)
    if old_canvas then LG.setCanvas({ old_canvas, stencil = Y }) else LG.setCanvas() end
    LG.setShader(old_shader)
    return canvas
end

--- Helper: send_capture_shader_uniforms
function send_capture_shader_uniforms(gm, shader, src, opts)
    if shader:hasUniform("texel_size") then shader:send("texel_size", { 1 / src:getWidth(), 1 / src:getHeight() }) end
    if shader:hasUniform("blur_radius") then shader:send("blur_radius", opts.snapshot_blur_radius or opts.blur_radius or 3.0) end
    if shader:hasUniform("dim_color") then shader:send("dim_color", opts.snapshot_dim_color or opts.dim_color or { 0, 0, 0, 0 }) end
    if shader:hasUniform("time") then shader:send("time", gm._T and gm._T.real_s or 0) end
end

--- Helper: enqueue_ease
local function enqueue_ease(EM, ref_table, ref_value, ease_to, delay, ease)
    EM:enqueue_event({ trigger = "ease", ease = ease or "lerp", blockable = N, no_delete = Y, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to, delay = delay })
    return Y
end

--- Helper: with_pause_open_transition_suppressed
local function with_pause_open_transition_suppressed(gm, fn)
    gm._suppress_pause_open_transition = Y
    local ok, ret = pcall(fn)
    gm._suppress_pause_open_transition = nil
    if not ok then error(ret) end
    return ret
end

--- Helper: capture
function M.capture(gm, opts)
    opts = opts or {}
    local widget = gm.UI and gm.UI.overlay_menu and gm.UI.overlay_menu.widget
    local canvas = M.capture_canvas(gm, opts);        if not canvas then return end

    gm.load_transition_snapshot = { canvas = canvas, fx_mask = 0, fx_mask_dir = opts.fx_mask_dir or 0, fx_mask_seed = opts.fx_mask_seed or 0, fx_mask_shader = "_-1_page_wipe", fx_mask_ref = "room", generic_id = widget and widget.ID or 0 }
    return gm.load_transition_snapshot
end

--- Helper: clear
function M.clear(gm) gm.load_transition_snapshot = nil; return Y end

--- Helper: clear_snapshot
local function clear_snapshot(gm, snapshot)
    if not snapshot or gm.load_transition_snapshot == snapshot then M.clear(gm) end
end

--- Helper: ease_out
function M.ease_out(gm, snapshot, delay)
    if snapshot then enqueue_ease(gm.E_MANAGER, snapshot, "fx_mask", 1, delay, "lerp") end
    return Y
end

--- Helper: clear_after
function M.clear_after(gm, delay, after, snapshot)  gm.E_MANAGER:enqueue_event({ no_delete = Y, trigger = "after", delay = delay, blocking = N, blockable = N, func = function() clear_snapshot(gm, snapshot); return after and after() or Y end }); return Y end

--- Helper: wipe_out
function M.wipe_out(gm, snapshot, delay, after)
    M.ease_out(gm, snapshot, delay)
    M.clear_after(gm, delay, after, snapshot)
    return Y
end

--- Helper: open_pause_under_snapshot
function M.open_pause_under_snapshot(gm, fade_time)
    with_pause_open_transition_suppressed(gm, function() require("HMui.menu.menu_mgr").open_pause_menu(gm) end)

    local OM = gm.UI.overlay_menu;        if not OM then return end
    ChildFadeTree.set_tree_alpha(OM.widget, 0)
    PanelFadeTree.set_tree_alpha(OM.attached_panel, 0)
    ChildFadeTree.fade_tree_in(OM.widget, gm, fade_time or 0.42)
    PanelFadeTree.fade_tree_in(gm, OM.attached_panel, fade_time or 0.42)
    return OM
end

return M
