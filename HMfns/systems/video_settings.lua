local LG, LW, LS = love.graphics, love.window, love.system

local M = {}

--- Helper: copy_res
local function copy_res(res) if not res then return end; return { w = res.w or res.width, h = res.h or res.height } end

--- Helper: valid_res
local function valid_res(res) return res and tonumber(res.w or res.width) and tonumber(res.h or res.height) end

--- Helper: clamp_res
local function clamp_res(res, fallback)
    local out = copy_res(valid_res(res) and res or fallback or { w = LG.getWidth(), h = LG.getHeight() })
    out.w, out.h = math.max(1, math.floor(out.w + 0.5)), math.max(1, math.floor(out.h + 0.5))
    return out
end

--- Helper: settings
local function settings(gm) gm.SET.s_win = gm.SET.s_win or {}; return gm.SET.s_win end

--- Helper: queue
local function queue(gm) gm.SET.queued_c = gm.SET.queued_c or {}; return gm.SET.queued_c end

--- Helper: selected_display
local function selected_display(gm, pending) local SW, Q = settings(gm), pending or queue(gm); return Q.selected_display or SW.selected_display or 1 end

--- Helper: resolved_screenmode
local function resolved_screenmode(value) return value == "auto" and "Borderless" or value end

--- Helper: selected_screenmode
local function selected_screenmode(gm, pending) local SW, Q = settings(gm), pending or queue(gm); return resolved_screenmode(Q.screenmode or SW.screenmode or "auto") end

--- Helper: fullscreentype
local function fullscreentype(screenmode) if screenmode == "Borderless" then return "desktop" end; if screenmode == "Fullscreen" then return "exclusive" end end

--- Helper: desktop_res
local function desktop_res(display) local w, h = LW.getDesktopDimensions(display); return { w = w or LG.getWidth(), h = h or LG.getHeight() } end

--- Helper: display_cache
local function display_cache(gm, display)
    local SW = settings(gm)
    SW.s_disp = SW.s_disp or {}
    SW.s_disp[display] = SW.s_disp[display] or {}
    return SW.s_disp[display]
end

--- Helper: render_scale
local function render_scale(res)
    local w, h = LG.getWidth(), LG.getHeight()
    return math.max(0.1, math.min(1, math.min((res.w or w)/w, (res.h or h)/h)))
end

--- Helper: resize_canvas
local function resize_canvas(gm, invalidate_snapshots)
    if invalidate_snapshots then gm.overlay_bg_canvas, gm.modal_bg_canvas = nil, nil end
    love.resize(LG.getWidth(), LG.getHeight())
end

--- Helper: invalidate_card_front_canvases
function M.invalidate_card_front_canvases(gm)
    local cards = gm and gm.R and gm.R.CARD
    if not cards then return end

    for _, card in pairs(cards) do
        local front = card.children and card.children.front
        if front and front.face_canvas then front.face_dirty = true end
        local mesh_card = card.children and card.children.mesh_card
        if mesh_card then mesh_card.needs_mesh_sync = true end
        card.fx_mask_canvas = nil
    end
end

--- Helper: window_res
local function window_res(gm, screenmode, display, render_res)
    if screenmode == "Borderless" then return desktop_res(display) end
    if screenmode == "Fullscreen" then return clamp_res(render_res, desktop_res(display)) end
    local desktop = desktop_res(display)
    local res = clamp_res(render_res, { w = math.min(1280, desktop.w), h = math.min(720, desktop.h) })
    return { w = math.min(res.w, desktop.w), h = math.min(res.h, desktop.h) }
end

--- Helper: mode_options
local function mode_options(screenmode, display, vsync)
    return {
        fullscreen = screenmode ~= "Windowed",
        fullscreentype = fullscreentype(screenmode),
        vsync = vsync,
        resizable = true,
        display = display,
        highdpi = LS.getOS() == "OS X",
    }
end

--- Helper: apply_window_settings
function M.apply_window_settings(gm, pending, initial)
    if not (gm and gm.SET) then return end
    local SET, SW = gm.SET, settings(gm)
    local Q = (pending and pending.queued_c) or SET.queued_c or {}

    SW.screenmode = Q.screenmode or SW.screenmode or "auto"
    SW.selected_display = Q.selected_display or SW.selected_display or 1
    SW.vsync = Q.vsync ~= nil and Q.vsync or SW.vsync or 1

    local display = SW.selected_display
    local screenmode = resolved_screenmode(SW.screenmode)
    local fallback_res = (screenmode == "Borderless" and desktop_res(display)) or display_cache(gm, display).screen_res
    local auto_res = Q.screenres == "auto" or (Q.screenres == nil and SET.screen_res == "auto")
    local render_res = auto_res and desktop_res(display) or clamp_res(Q.screenres or SET.screen_res or fallback_res, desktop_res(display))
    SET.screen_res = auto_res and "auto" or copy_res(render_res)
    display_cache(gm, display).screen_res = copy_res(render_res)

    local win_res = window_res(gm, screenmode, display, render_res)
    LW.updateMode(win_res.w, win_res.h, mode_options(screenmode, display, SW.vsync))
    gm.rcfg.s_canvas = render_scale(render_res)
    M.invalidate_card_front_canvases(gm)
    resize_canvas(gm, true)

    SET.queued_c = {}
    if initial ~= true and gm.save_settings then gm:save_settings() end
end

return M
