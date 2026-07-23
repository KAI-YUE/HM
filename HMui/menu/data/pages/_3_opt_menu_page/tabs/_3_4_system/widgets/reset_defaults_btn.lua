local C             = require("HMfns.animate.color.color_const")
local Common        = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.common")
local ConfirmPopup  = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")
local ControlState  = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local AudioEntries  = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio.entries")
local VisionEntries = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision.entries")
local ControlEntries = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_3_control.entries")
local SystemEntries = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.entries")

local c_tape = C.DEC.TAPE

local Y, N = true, false

local M = {}

local EntrySets = {
    { entries = AudioEntries,   owner_key = "s_snd" },
    { entries = VisionEntries,  owner_key = "vision" },
    { entries = ControlEntries },
    { entries = SystemEntries },
}

local VisionOwners = {
    graphics_quality = "s_graphics",
    vsync            = "queued_c",
}

local popup_args = {
    ui_key              = "reset_defaults_confirm",     queue        = "reset_defaults_confirm",
    id_prefix           = "reset_defaults_confirm",     prompt_key   = "options.system.reset_defaults_warning",
    prompt_i18n_prefix  = "",                           text_wrap    = Y,
    text_maxw           = 6.9,                          text_box_T   = { x = 0, y = -.25, w = 8.1, h = 3.35 },
}

-----------------------------
--- reset values
----------------------------------
--- Helper: default_value | resettable_entry | reset_value
local function default_value(entry)    if entry.default ~= nil then return entry.default end; if entry.default_on ~= nil then return entry.default_on end end
local function resettable_entry(entry) return entry and entry.key and entry.key ~= "language" and entry.control ~= "widget_with_btn" end
local function reset_value(entry, value) if entry.key == "vsync" then return value ~= N and 1 or 0 end; return value end

--- Helper: reset_owner_key | reset_entry
local function reset_owner_key(set, entry)
    if set.owner_key == "vision" then return VisionOwners[entry.key] end
    return set.owner_key
end

local function reset_entry(gm, set, entry)
    if not resettable_entry(entry) then return end
    local value = default_value(entry);                          if value == nil then return end
    local owner_key = reset_owner_key(set, entry)
    if owner_key then return ControlState.set_preview_in(gm, owner_key, entry.key, reset_value(entry, value)) end
    return ControlState.set_preview(gm, entry.key, value)
end

--- Helper: reset_settings
local function reset_settings(gm)
    for _, set in ipairs(EntrySets) do
        for _, entry in ipairs(set.entries or {}) do reset_entry(gm, set, entry) end
    end
end

--- Helper: remove_reset_popup | reset_yes | reset_no | show_reset_popup
local function remove_reset_popup(gm)  ConfirmPopup.remove_popup(gm, popup_args) end
local function reset_yes(gm)           remove_reset_popup(gm); return reset_settings(gm) end
local function reset_no(gm)            return remove_reset_popup(gm) end
local function show_reset_popup(gm)    popup_args.yes_hook_fn, popup_args.no_hook_fn = reset_yes, reset_no; return ConfirmPopup.show_popup(gm, popup_args) end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args = Common.base_args(gm, entry)
    --- paper setting 
    args.button_quad_key                       = "paper-2" 
    args.icon_quad_key,   args.button_w        = "undo",    1.
    args.control_w,       args.icon_shadow     = 1.25,      N
    args.icon_offset_y                         = -0.1
    
    --- pinner setting 
    args.pin_quad_key                          = "tape-1"
    args.pin_tint,        args.pin_shadow      = c_tape,    N
    args.pin_offset_x,    args.pin_offset_y    = -.5,    -0.01
    args.pin_w,           args.pin_r           =  1.1,   -0.42 
    
    --- wrap_on_change false, does not have temporary preview
    args.wrap_on_change,  args.on_click         = N,     function(_gm) return show_reset_popup(_gm) end
    return args
end

return M
