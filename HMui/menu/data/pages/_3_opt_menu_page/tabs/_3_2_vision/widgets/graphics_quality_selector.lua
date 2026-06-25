local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local M = {}

local T_graphics_quality = {
    { key = "low",    label_key = "quality_low",    fallback = "Low" },
    { key = "medium", label_key = "quality_medium", fallback = "Medium" },
    { key = "high",   label_key = "quality_high",   fallback = "High" },
}

--- Helper: graphics_quality_value | graphics_quality_options | set_pending_graphics_quality
local function graphics_quality_value(gm, entry) return (gm.SET.s_graphics.graphics_quality) or entry.default or "auto" end
local function graphics_quality_options(gm)      local opts = { Common.auto_option(gm) }; for _, item in ipairs(T_graphics_quality) do opts[#opts + 1] = { key = item.key, value = item.key, label = Common.vision_text(gm, item.label_key, item.fallback) } end; return opts end
local function set_pending_graphics_quality(gm, value) return ControlState.set_preview_in(gm, "s_graphics", "graphics_quality", value) end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args = Common.base_args(gm, entry)

    args.value,            args.options                  = graphics_quality_value(gm, entry), graphics_quality_options(gm)
    args.value_text_scale, args.value_char_w_factor      = 0.42, 0.42
    args.value_max_w,      args.value_text_box_w_factor  = 3.35, 1.4
    args.value_text_inset, args.value_text_wrap          = 0.12, false

    args.on_change = function(_gm, _, value) return set_pending_graphics_quality(_gm, value) end
    return args
end

return M
