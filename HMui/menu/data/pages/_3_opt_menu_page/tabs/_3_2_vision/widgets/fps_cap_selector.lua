local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local M = {}

local T_fps_caps = { 30, 60, 120, 144, 240 }
local _auto_fps_cap = 500

--- Helper: fps_cap_value | fps_cap_options | set_pending_fps_cap
local function fps_cap_value(gm, entry) return gm.SET.fps_cap or gm.FPS_CAP or entry.default or "auto" end
local function fps_cap_options(gm)     local opts = { Common.auto_option(gm) }; for _, cap in ipairs(T_fps_caps) do opts[#opts + 1] = { key = cap, value = cap, label = cap >= 500 and Common.vision_text(gm, "unlimited", "Unlimited") or tostring(cap) } end; return opts end
local function set_pending_fps_cap(gm, entry, value) return ControlState.set_preview(gm, "fps_cap", value == "auto" and "auto" or tonumber(value) or entry.default or _auto_fps_cap) end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args = Common.base_args(gm, entry)

    args.value,             args.options                  = fps_cap_value(gm, entry), fps_cap_options(gm)
    args.value_text_scale,  args.value_char_w_factor      = 0.42, 0.42
    args.value_max_w,       args.value_text_box_w_factor  = 3.35, 1.4
    args.value_text_inset,  args.value_text_wrap          = 0.12, N

    args.on_change = function(_gm, _, value) return set_pending_fps_cap(_gm, entry, value) end
    return args
end

return M
