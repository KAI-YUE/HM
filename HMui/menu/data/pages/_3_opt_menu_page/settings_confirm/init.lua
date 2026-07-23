local UI      = require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm.ui_helpers")
local Backend = require("HMui.menu.data.pages._3_opt_menu_page.settings_confirm.backend")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")

local M = {}

---------------------------------------------------
--- show
---------------------------------------------------
function M.show(gm, opts)
    gm.opt_system_confirm_no_action = opts and opts.no_action
    gm.opt_system_confirm_yes_action = opts and opts.yes_action
    UI.show_popup(gm)
end
function M.open_system_settings_confirm(gm) M.show(gm) end

---------------------------------------------------
--- gate changed system settings
---------------------------------------------------
--- Helper: has_system_settings_changes
function M.has_system_settings_changes(gm) return ControlState.has_changes(gm) end

--- Helper: open_system_settings_confirm_if_changed
function M.open_system_settings_confirm_if_changed(gm, opts)
    if not M.has_system_settings_changes(gm) then return false end
    M.show(gm, opts)
    return true
end

-------------------------------------------------
--- confirm system settings no
-------------------------------------------------
function M.confirm_system_settings_no(gm) Backend.cancel_confirm(gm) end

-------------------------------------------------
--- confirm system settings yes
-------------------------------------------------
function M.confirm(gm) Backend.confirm_settings(gm) end
function M.confirm_system_settings_yes(gm) M.confirm(gm) end

-------------------------------------------------
--- discard system settings
-------------------------------------------------
function M.discard_settings(gm) Backend.discard_settings(gm) end

return M
