return function(GMgr)
local PageTunnel   = require("HMGmgr.ui_render.transitions.page.tunnel")
local PageAnimator = require("HMGmgr.ui_render.transitions.page.animator")
local LoadSnapshot = require("HMGmgr.ui_render.transitions.load_snapshot")

-----------------------------
--- transition bindings
----------------------------------
--- Helper: bind_methods
local function bind_methods(GMgr, mod, names)
    for _, name in ipairs(names) do
        local fn_name = name
        GMgr[fn_name] = function(self, ...) return mod[fn_name](self, ...) end
    end
end

--- Helper: bind static
local function bind_static(GMgr, mod, names)
    for _, name in ipairs(names) do
        local fn_name = name
        GMgr[fn_name] = function(self, ...) return mod[fn_name](...) end
    end
end

-----------------------------
--- page tunnel
----------------------------------
bind_methods(GMgr, PageTunnel, {
    "_send_page_tunnel_uniforms",
    "_send_page_tunnel_hold_filter_uniforms",
    "_lock_page_tunnel_transition",
    "_clear_page_tunnel_transition",
    "_maybe_fire_page_tunnel_cover",
    "_maybe_start_page_tunnel_reveal",
    "_page_tunnel_progress",
    "_page_tunnel_hides_scene",
    "_page_tunnel_renders_hold_scene",
    "_ensure_page_tunnel_hold_filter",
    "_draw_page_tunnel_hold_filter",
    "_ensure_page_tunnel_cover_wipe",
    "_draw_page_tunnel_cover_wipe",
    "_draw_page_tunnel_transition",
})

bind_static(GMgr, PageTunnel, {
    "_page_tunnel_cover_point",
    "_page_tunnel_fade_out_start",
})

-----------------------------
--- page animator
----------------------------------
bind_methods(GMgr, PageAnimator, {
    "_page_animator_param_progress",
    "_page_animator_progress",
    "_page_animator_wipe_progress",
    "_lock_page_animator_transition",
    "_clear_page_animator_transition",
    "_maybe_fire_page_animator_cover",
    "_page_animator_hides_scene",
    "_preload_page_animator_actor",
    "_release_page_animator_actor",
    "_ensure_page_animator_actor",
    "_draw_page_animator_transition",
})

-----------------------------
--- snapshots
----------------------------------
bind_methods(GMgr, LoadSnapshot, {
    "_draw_load_transition_snapshot",
})
end
