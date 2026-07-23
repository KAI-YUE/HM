local LG, LW, LS = love.graphics, love.window, love.system

local Y = true

local M = {}

--- Helper: queued_settings | window_settings | focused_display
function M.queued_settings(gm)  local SET = gm.SET; SET.queued_c = SET.queued_c or {}; return SET.queued_c end
function M.window_settings(gm)  local SET = gm.SET; SET.s_win    = SET.s_win or {};    return SET.s_win end
function M.focused_display(gm)  local SW, Q = M.window_settings(gm), M.queued_settings(gm); return Q.selected_display or SW.selected_display or 1 end

--- Helper: resolved_screenmode | focused_screenmode | fullscreentype
function M.resolved_screenmode(value) return value == "auto" and "Borderless" or value end
function M.focused_screenmode(gm)     local SW, Q = M.window_settings(gm), M.queued_settings(gm); return M.resolved_screenmode(Q.screenmode or SW.screenmode or "auto") end
function M.fullscreentype(screenmode) if screenmode == "Borderless" then return "desktop" end; if screenmode == "Fullscreen" then return "exclusive" end end

--- Helper: display_cache
function M.display_cache(gm, display)
    local SW  = M.window_settings(gm)
    SW.s_disp = SW.s_disp or {}
    SW.s_disp[display] = SW.s_disp[display] or {}
    return SW.s_disp[display]
end

--- Helper: current_window_size | desktop_resolution | auto_resolution
function M.current_window_size()       return { w = LG.getWidth(), h = LG.getHeight() } end
function M.desktop_resolution(display) local w, h = LW.getDesktopDimensions(display); return { w = w or LG.getWidth(), h = h or LG.getHeight() } end
function M.auto_resolution(display)    return M.desktop_resolution(display) end

--- Helper: clamp_resolution
function M.clamp_resolution(res, fallback)
    local out = res or fallback or M.current_window_size()
    return { w = math.max(1, math.floor((tonumber(out.w or out.width) or LG.getWidth()) + 0.5)), h = math.max(1, math.floor((tonumber(out.h or out.height) or LG.getHeight()) + 0.5)) }
end

--- Helper: live_mode_options
function M.live_mode_options(screenmode, display, vsync)
    return {
        fullscreen  = screenmode ~= "Windowed",  fullscreentype = M.fullscreentype(screenmode),
        vsync       = vsync,                     resizable      = Y,
        display     = display,                   highdpi        = (LS.getOS() == "OS X"),
    }
end

--- Helper: current_resolution
function M.current_resolution(gm)
    local SW, Q, display  = M.window_settings(gm),              M.queued_settings(gm), M.focused_display(gm)
    local disp, SET       = SW.s_disp and SW.s_disp[display], gm.SET
    if M.focused_screenmode(gm) == "Borderless" then return M.desktop_resolution(display) end
    if Q.screenres    then return Q.screenres == "auto" and M.auto_resolution(display) or Q.screenres end
    if SET.screen_res then return SET.screen_res == "auto" and M.auto_resolution(display) or SET.screen_res end
    return (disp and disp.screen_res) or M.current_window_size()
end

--- Helper: applied_resolution
function M.applied_resolution(gm)
    local SW,   display  = M.window_settings(gm), M.focused_display(gm)
    local disp, SET      = SW.s_disp and SW.s_disp[display], gm.SET
    if M.focused_screenmode(gm) == "Borderless" then return M.desktop_resolution(display) end
    if SET.screen_res                         then return SET.screen_res == "auto" and M.auto_resolution(display) or SET.screen_res end
    return (disp and disp.screen_res) or M.current_window_size()
end

return M
