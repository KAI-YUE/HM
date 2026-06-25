local Common = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.common")
local State  = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.resolution_selector.state")

local Y = true

local M = {}

local T_windowed_resolutions = {
    { w = 1280, h = 720  },
    { w = 1366, h = 768  },     { w = 1600, h = 900  },
    { w = 1920, h = 1080 },     { w = 2560, h = 1440 },
}

--- Helper: resolution_key | resolution_label | resolution_option
function M.resolution_key(res)   if not res then return "" end; return tostring(res.w or res.width or 0) .. "x" .. tostring(res.h or res.height or 0) end
function M.resolution_label(res) return tostring(res.w or res.width or 0) .. " X " .. tostring(res.h or res.height or 0) end
local function resolution_option(res, display_lang) local w, h = res.w or res.width or 0, res.h or res.height or 0; return { key = M.resolution_key(res), value = M.resolution_key(res), label = w .. " X " .. h, lang = display_lang } end

--- Helper: add_resolution
local function add_resolution(values, seen, res, max_res)
    local w, h = tonumber(res and (res.w or res.width)), tonumber(res and (res.h or res.height))
    if not (w and h) then return end
    if max_res and (w > max_res.w or h > max_res.h) then return end
    local key = M.resolution_key({ w = w, h = h })
    if seen[key] then return end
    seen[key] = Y
    values[#values + 1] = { w = w, h = h }
end

--- Helper: fullscreen_resolutions
local function fullscreen_resolutions(display)
    local values, seen = {}, {}
    for _, res in ipairs(love.window.getFullscreenModes(display) or {}) do add_resolution(values, seen, res) end
    table.sort(values, function(a, b) return a.w == b.w and a.h < b.h or a.w < b.w end)
    return values
end

--- Helper: closest_resolution | borderless_resolution
local function closest_resolution(target, values)
    local best, best_d = target, nil
    for _, res in ipairs(values or {}) do
        local dw, dh  = (res.w or 0) - (target.w or 0), (res.h or 0) - (target.h or 0)
        local d       = dw*dw + dh*dh
        if not best_d or d < best_d then best, best_d = res, d end
    end
    return { w = best.w or target.w, h = best.h or target.h }
end

function M.borderless_resolution(gm, display)
    display = display or State.focused_display(gm)
    local desktop = State.desktop_resolution(display)
    return closest_resolution(desktop, fullscreen_resolutions(display))
end

--- Helper: windowed_resolutions | add_windowed_fallbacks
local function windowed_resolutions(display, current)
    local values, seen, desktop = {}, {}, State.desktop_resolution(display)
    for _, res in ipairs(T_windowed_resolutions) do add_resolution(values, seen, res, desktop) end
    add_resolution(values, seen, current, desktop)
    table.sort(values, function(a, b) return a.w == b.w and a.h < b.h or a.w < b.w end)
    return values
end

local function add_windowed_fallbacks(values, seen, display, current)
    local desktop = State.desktop_resolution(display)
    for _, res in ipairs(T_windowed_resolutions) do add_resolution(values, seen, res, desktop) end
    add_resolution(values, seen, current, desktop)
end

--- Helper: resolution_values
local function resolution_values(gm)
    local display, screenmode, current = State.focused_display(gm), State.focused_screenmode(gm), State.current_resolution(gm)
    if screenmode == "Fullscreen" then
        local values, seen = fullscreen_resolutions(display), {}
        for _, res in ipairs(values) do seen[M.resolution_key(res)] = Y end
        if #values <= 1 then add_windowed_fallbacks(values, seen, display, current) end
        table.sort(values, function(a, b) return a.w == b.w and a.h < b.h or a.w < b.w end)
        return values
    end
    if screenmode == "Borderless" then return { M.borderless_resolution(gm, display) } end
    return windowed_resolutions(display, current)
end

--- Helper: cache_resolutions
local function cache_resolutions(gm, display, values)
    local disp = State.display_cache(gm, display)
    disp.screen_resolutions = { strings = {}, values = {} }
    for i, res in ipairs(values) do
        disp.screen_resolutions.strings[i] = M.resolution_label(res)
        disp.screen_resolutions.values[i]  = { w = res.w, h = res.h }
    end
    disp.screen_res = disp.screen_res or State.current_resolution(gm)
end

--- Helper: resolution_options | resolution_value_key | resolution_arrows_disabled
function M.resolution_options(gm)
    local opts, display_lang = { Common.auto_option(gm) }, Common.sab_lang(gm)
    local display, values = State.focused_display(gm), resolution_values(gm)

    if #values == 0 then values[1] = State.current_resolution(gm) end
    cache_resolutions(gm, display, values)
    for _, res in ipairs(values) do opts[#opts + 1] = resolution_option(res, display_lang) end
    return opts
end

function M.resolution_value_key(gm)
    local Q = State.queued_settings(gm)
    if Q.screenres == "auto" or (Q.screenres == nil and gm.SET.screen_res == "auto") then return "auto" end
    if Q.screenres then return M.resolution_key(Q.screenres) end
    return M.resolution_key(State.current_resolution(gm))
end

function M.resolution_arrows_disabled(gm)
    return State.focused_screenmode(gm) == "Borderless" and M.resolution_value_key(gm) ~= "auto"
end

return M
