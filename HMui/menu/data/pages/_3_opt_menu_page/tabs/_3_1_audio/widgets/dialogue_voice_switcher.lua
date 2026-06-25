local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local N = false

local M = {}

--- Helper: sound_settings
local function sound_settings(gm) gm.SET.s_snd = gm.SET.s_snd or {}; return gm.SET.s_snd end

--- Helper: dialogue_voice_on
local function dialogue_voice_on(gm) return sound_settings(gm).dialogue_voice ~= N end

--- Helper: dialogue_voice_text
local function dialogue_voice_text(gm) local on = dialogue_voice_on(gm); return Common.audio_text(gm, on and "on" or "off", on and "On" or "Off") end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args  = Common.base_args(gm, entry)

    args.on,       args.value      = dialogue_voice_on(gm), dialogue_voice_text(gm)
    args.on_label, args.off_label  = Common.audio_text(gm, "on", "ON"), Common.audio_text(gm, "off", "OFF")

    args.on_change = function(_gm, _, value) return ControlState.set_preview_in(_gm, "s_snd", entry.key, value) end
    return args
end

return M
