local ConfirmPopup = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")

local M = {}

local popup_args = {
    text_box_T      = { x = 0, y = -.25, w = 8.1, h = 3.35 },
    ui_key          = "system_settings_confirm",
    queue           = "system_settings_confirm",
    id_prefix       = "system_settings_confirm",
    prompt_key      = "apply_settings",
    prompt_fallback = "Apply all changes?",
    yes_hook_fn     = "confirm_system_settings_yes",
    no_hook_fn      = "confirm_system_settings_no",
}

---------------------------------
--- remove_popup
---------------------------------
function M.remove_popup(gm) ConfirmPopup.remove_popup(gm, popup_args) end

--------------------------------
--- show_popup
--------------------------------
function M.show_popup(gm) ConfirmPopup.show_popup(gm, popup_args) end

return M
