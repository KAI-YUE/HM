local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local min, max = math.min, math.max

local M = {}

--- Helper: slider_value
local function slider_value(gm, entry)
    local min_val, max_val  = entry.min_val, entry.max_val
    local value             = tonumber(gm.SET[entry.key]) or entry.default or min_val or 0
    if min_val then value = max(min_val, value) end
    if max_val then value = min(max_val, value) end
    return value
end

--- Helper: slider_fields
local function slider_fields(args, entry) for _, key in ipairs({ "min_val", "max_val", "steps", "decimals" }) do args[key] = entry[key] end end

--- Helper: set_pending_slider_value
local function set_pending_slider_value(gm, entry, value)
    local min_val, max_val  = entry.min_val or 0, entry.max_val or 1
    local out               = min_val + (max_val - min_val)*value
    
    if not entry.decimals or entry.decimals <= 0 then out = math.floor(out + 0.5) end
    ControlState.set_preview(gm, entry.key, out)
end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args      = Common.base_args(gm, entry)
    args.value      = slider_value(gm, entry)
    args.on_change  = function(_gm, _, value) return set_pending_slider_value(_gm, entry, value) end
    slider_fields(args, entry)
    return args
end

return M
