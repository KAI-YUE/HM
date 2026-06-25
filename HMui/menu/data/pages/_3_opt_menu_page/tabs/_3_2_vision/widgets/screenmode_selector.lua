local Common        = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.common")
local ControlState  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local Resolution    = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.resolution_selector")
local VideoSettings = require("HMfns.systems.video_settings")
local PageAnimator  = require("HMui.menu.transitions.page.animator")
local Tree          = require("HMEng.ui_actors.common.tree")
local C             = require("HMfns.animate.color.color_const")
local LG, LW, LS    = love.graphics, love.window, love.system

local min, max = math.min, math.max
local floor = math.floor

local Y, N = true, false

local M = {}

local T_label_w_by_lang = { es_419 = 3.5, es_ES = 3.5 }
local _default_row_gap  = 0.2

local T_screen_modes = {
    { key = "Windowed",   label_key = "windowed",    fallback = "Windowed" },
    { key = "Fullscreen", label_key = "full_screen", fallback = "Full Screen" },
    { key = "Borderless", label_key = "borderless",  fallback = "Borderless" },
}

--- Helper: queued_settings | window_settings
local function queued_settings(gm)  local SET = gm.SET; SET.queued_c = SET.queued_c or {}; return SET.queued_c end
local function window_settings(gm)  local SET = gm.SET; SET.s_win    = SET.s_win or {};    return SET.s_win end

--- Helper: auto_screenmode
local function auto_screenmode()    return "Borderless" end

--- Helper: resolved_screenmode
local function resolved_screenmode(value) return value == "auto" and auto_screenmode() or value end

--- Helper: screenmode_value
local function screenmode_value(gm) local SW, Q = window_settings(gm), queued_settings(gm); return Q.screenmode or SW.screenmode or "auto" end

--- Helper: fullscreentype
local function fullscreentype(screenmode) if screenmode == "Borderless" then return "desktop" end; if screenmode == "Fullscreen" then return "exclusive" end end

--- Helper: copy_res
local function copy_res(res) if not res then return end; return { w = res.w or res.width, h = res.h or res.height } end

--- Helper: clamp_res
local function clamp_res(res, fallback)
    local out = copy_res(res) or copy_res(fallback) or { w = LG.getWidth(), h = LG.getHeight() }
    out.w, out.h = max(1, floor((tonumber(out.w) or LG.getWidth()) + 0.5)), max(1, floor((tonumber(out.h) or LG.getHeight()) + 0.5))
    return out
end

--- Helper: display_caches
local function display_cache(gm, display)
    local SW = window_settings(gm)
    SW.s_disp = SW.s_disp or {}
    SW.s_disp[display] = SW.s_disp[display] or {}
    return SW.s_disp[display]
end

--- Helper: desktop_resolution
local function desktop_resolution(display) local w, h = LW.getDesktopDimensions(display); return { w = w or LG.getWidth(), h = h or LG.getHeight() } end

--- Helper: auto_resolution
local function auto_resolution(display)    return desktop_resolution(display) end

--- Helper: render_scale | resolution_label
local function render_scale(res)           local w, h = LG.getWidth(), LG.getHeight(); return max(0.1, min(1, min((res.w or w)/w, (res.h or h)/h))) end
local function resolution_label(res)       return tostring(res.w or res.width or 0) .. " X " .. tostring(res.h or res.height or 0) end

--- Helper: option_root
local function option_root(gm)
    local OM = gm and gm.UI and gm.UI.overlay_menu
    return OM and (OM.UIRoot or OM.widget)
end

--- Helper: find_option_child
local function find_option_child(gm, id) return Tree.find_child_by_id(option_root(gm), id) end

--- Helper: set_arrow_disabled
local function set_arrow_disabled(arrow, disabled)
    local cfg, st = arrow and arrow.config, arrow and arrow.states
    if not (cfg and st) then return end
    cfg.button, cfg.can_hover, cfg.can_click = not disabled, not disabled, not disabled
    cfg.hover_zoom, cfg.hover_shake = disabled and 1 or 1.12, not disabled and { x = 0.02, y = 0.015, r = 0.04, speed = 32, settle = 8 } or N
    cfg.tint, cfg.sprite_color = disabled and C.UI.INACTIVE or C.CREAM, disabled and C.UI.INACTIVE or C.CREAM
    cfg.shadow_color = disabled and { 0, 0, 0, 0.12 } or { 0, 0, 0, 0.30 }
    st.hover.can, st.hover.is, st.click.can, st.collide.can = not disabled, N, not disabled, not disabled
end

--- Helper: sync_resolution_chip
local function sync_resolution_chip(gm, res)
    local chip = find_option_child(gm, "vision_resolution_value")
    if not (chip and chip.config and res) then return end
    chip.config.text, chip.config.lang = resolution_label(res), Common.sab_lang(gm)
end

--- Helper: sync_resolution_arrows
local function sync_resolution_arrows(gm, disabled)
    set_arrow_disabled(find_option_child(gm, "vision_resolution_prev"), disabled)
    set_arrow_disabled(find_option_child(gm, "vision_resolution_next"), disabled)
end

--- Helper: force_borderless_resolution
local function force_borderless_resolution(gm, display)
    local res = Resolution.borderless_resolution(gm, display)
    ControlState.set_preview_in(gm, "queued_c", "screenres", res)
    sync_resolution_chip(gm, res)
    return res
end

--- Helper: preview_window_resolution
local function preview_window_resolution(screenmode, display, render_res)
    if screenmode == "Borderless" then return desktop_resolution(display) end
    if screenmode == "Fullscreen" then return clamp_res(render_res, desktop_resolution(display)) end
    local desktop = desktop_resolution(display)
    local res = clamp_res(render_res, { w = min(1280, desktop.w), h = min(720, desktop.h) })
    return { w = min(res.w, desktop.w), h = min(res.h, desktop.h) }
end

--- Helper: preview_mode_options
local function preview_mode_options(screenmode, display, vsync)
    return {
        fullscreen = screenmode ~= "Windowed",
        fullscreentype = fullscreentype(screenmode),
        vsync = vsync,
        resizable = Y,
        display = display,
        highdpi = LS.getOS() == "OS X",
    }
end

--- Helper: live_preview_screenmode
local function live_preview_screenmode(gm)
    local SET, SW, Q = gm.SET, window_settings(gm), queued_settings(gm)
    local screenmode = resolved_screenmode(Q.screenmode or SW.screenmode or "auto")
    local display = Q.selected_display or SW.selected_display or 1
    local cached = display_cache(gm, display)
    if screenmode == "Borderless" then force_borderless_resolution(gm, display) end
    sync_resolution_arrows(gm, screenmode == "Borderless")
    local render_res = (Q.screenres == "auto" or (Q.screenres == nil and SET.screen_res == "auto")) and auto_resolution(display) or clamp_res(Q.screenres or SET.screen_res or cached.screen_res or { w = LG.getWidth(), h = LG.getHeight() }, desktop_resolution(display))
    local win_res = preview_window_resolution(screenmode, display, render_res)

    LW.updateMode(win_res.w, win_res.h, preview_mode_options(screenmode, display, Q.vsync ~= nil and Q.vsync or SW.vsync or 1))
    if gm.rcfg then gm.rcfg.s_canvas = render_scale(render_res) end
    VideoSettings.invalidate_card_front_canvases(gm)
    PageAnimator.clear(gm)
    gm.overlay_bg_canvas, gm.modal_bg_canvas, gm.load_transition_snapshot, gm.title_page_options_snapshot, gm.page_tunnel_transition, gm.page_animator_transition = nil, nil, nil, nil, nil, nil
    love.resize(LG.getWidth(), LG.getHeight())
end

--- Helper: set_pending_screenmode
local function set_pending_screenmode(gm, value)  return ControlState.set_preview_in(gm, "queued_c", "screenmode", value, live_preview_screenmode) end

--- Helper: screenmode_options
local function screenmode_options(gm)
    local opts = { Common.auto_option(gm) }
    for _, item in ipairs(T_screen_modes) do opts[#opts + 1] = { key = item.key, value = item.key, label = Common.vision_text(gm, item.label_key, item.fallback) } end
    return opts
end

--- Helper: screenmode_label_w
local function screenmode_label_w(gm) local lang = gm and gm.selected_lang; return T_label_w_by_lang[lang and lang.key] end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args = Common.base_args(gm, entry)
    local label_w = screenmode_label_w(gm)

    args.value,             args.options                  = screenmode_value(gm), screenmode_options(gm)
    args.value_text_scale,  args.value_char_w_factor      = 0.42, 0.42
    args.value_max_w,       args.value_text_box_w_factor  = 3.35, 1.
    args.value_text_inset,  args.value_text_wrap          = 0.12, N
    args.label_w,           args.value_gap                = label_w, _default_row_gap
    
    args.on_change = function(_gm, _, value) return set_pending_screenmode(_gm, value) end

    return args
end

return M
