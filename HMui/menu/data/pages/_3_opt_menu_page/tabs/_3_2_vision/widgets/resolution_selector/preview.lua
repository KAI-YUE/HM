local ControlState  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local State         = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.resolution_selector.state")
local VideoSettings = require("HMfns.systems.video_settings")
local PageAnimator  = require("HMui.menu.transitions.page.animator")

local LG, LW = love.graphics, love.window

local M = {}

--- Helper: live_preview_resolution
local function live_preview_resolution(gm)
    local SW,         Q        = State.window_settings(gm),   State.queued_settings(gm)
    local screenmode, display  = State.focused_screenmode(gm), State.focused_display(gm)
    if screenmode ~= "Windowed" then return end

    local target = Q.screenres == "auto" and State.auto_resolution(display) or State.clamp_resolution(Q.screenres, State.desktop_resolution(display))
    LW.updateMode(target.w, target.h, State.live_mode_options(screenmode, display, Q.vsync ~= nil and Q.vsync or SW.vsync or 1))
    gm.rcfg.s_canvas = 1
    VideoSettings.invalidate_card_front_canvases(gm)
    PageAnimator.clear(gm)
    gm.overlay_bg_canvas, gm.modal_bg_canvas, gm.load_transition_snapshot, gm.title_page_options_snapshot, gm.page_tunnel_transition, gm.page_animator_transition = nil, nil, nil, nil, nil, nil
    love.resize(LG.getWidth(), LG.getHeight())
end

--- Helper: parse_resolution | set_pending_resolution
local function parse_resolution(value) local w, h = tostring(value or ""):match("^(%d+)x(%d+)$"); return { w = tonumber(w) or 1280, h = tonumber(h) or 720 } end

function M.set_pending_resolution(gm, value)
    if value == "auto" then return ControlState.set_preview_in(gm, "queued_c", "screenres", "auto", live_preview_resolution) end
    local res = parse_resolution(value)
    if not gm.option_menu_resolution_preview_base_res then
        local base = State.applied_resolution(gm)
        gm.option_menu_resolution_preview_base_res = { w = base.w or base.width, h = base.h or base.height }
    end
    return ControlState.set_preview_in(gm, "queued_c", "screenres", res, live_preview_resolution)
end

return M
