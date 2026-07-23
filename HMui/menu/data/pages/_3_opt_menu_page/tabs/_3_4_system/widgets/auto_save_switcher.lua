local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local N = false

local M = {}

--- Helper: auto_save_on | auto_save_text
local function auto_save_on(gm)   return gm.SET.auto_save ~= N end
local function auto_save_text(gm) local on = auto_save_on(gm); return Common.system_text(gm, on and "on" or "off", on and "On" or "Off") end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args  = Common.base_args(gm, entry)
    
    args.on,       args.value      = auto_save_on(gm), auto_save_text(gm)
    args.on_label, args.off_label  = Common.system_text(gm, "on", "ON"), Common.system_text(gm, "off", "OFF")

    args.on_change = function(_gm, _, value) return ControlState.set_preview(_gm, entry.key, value) end
    return args
end

return M
