local Common    = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.common")
local LRBackend = require("HMEng.ui_actors.hm_panel.prototype.control_panel.lr_selector.backend")
local Options   = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.resolution_selector.options")
local Preview   = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.widgets.resolution_selector.preview")

local N = false

local M = {}

M.borderless_resolution = Options.borderless_resolution

--- Helper: refresh_resolution_state
local function refresh_resolution_state(gm, state)
    state.options = Options.resolution_options(gm)
    state.idx = LRBackend.selected_index(state.options, Options.resolution_value_key(gm))
    return not Options.resolution_arrows_disabled(gm)
end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args = Common.base_args(gm, entry)

    args.value,             args.options                  = Options.resolution_value_key(gm), Options.resolution_options(gm)
    args.value_text_scale,  args.value_char_w_factor      = 0.42, 0.42
    args.value_max_w,       args.value_text_box_w_factor  = 3.35, 1.
    args.value_text_inset,  args.value_text_wrap          = 0.12, N
    args.arrows_disabled,   args.refresh_state            = Options.resolution_arrows_disabled(gm), refresh_resolution_state

    args.on_change = function(_gm, _, value) return Preview.set_pending_resolution(_gm, value) end

    return args
end

return M
