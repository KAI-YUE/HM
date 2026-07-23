local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local VideoSettings = require("HMfns.systems.video_settings")
local LW           = love.window

local N = false

local M = {}

--- Helper: queued_settings
local function queued_settings(gm) gm.SET.queued_c = gm.SET.queued_c or {}; return gm.SET.queued_c end

--- Helper: apply_v_sync
local function apply_v_sync(gm, _, value)
    if LW.setVSync then VideoSettings.invalidate_card_front_canvases(gm); return LW.setVSync(value) end
    local w, h, flags = LW.getMode()
    flags.vsync = value
    local ok = LW.updateMode(w, h, flags)
    VideoSettings.invalidate_card_front_canvases(gm)
    return ok
end

--- Helper: v_sync_on
local function v_sync_on(gm)
    local Q, SW = queued_settings(gm), gm.SET.s_win or {}
    if Q.vsync ~= nil then return Q.vsync ~= 0 end
    return SW.vsync ~= 0
end

--- Helper: v_sync_text
local function v_sync_text(gm) local on = v_sync_on(gm); return Common.vision_text(gm, on and "on" or "off", on and "On" or "Off") end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args = Common.base_args(gm, entry)

    args.on,       args.value      = v_sync_on(gm), v_sync_text(gm)
    args.on_label, args.off_label  = Common.vision_text(gm, "on", "ON"), Common.vision_text(gm, "off", "OFF")

    args.on_change = function(_gm, _, value) return ControlState.set_preview_in(_gm, "queued_c", entry.key, value ~= N and 1 or 0, apply_v_sync) end
    return args
end

return M
