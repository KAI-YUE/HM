local ConfirmPopup  = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")
local TabDef        = require("HMui.menu.data.pages._1_load_2_save_pages._shared.confirm_tab_def")

local M = {}

local popup_args = {
    text_box_T      = { x = 0, y = 0.45, w = 8.1, h = 3.35 },
    -- text_offset     = { x = 0, y = 1 },
    ui_key          = "load_slot_confirm",
    slot_key        = "load_slot_confirm_slot_idx",
    queue           = "load_slot_confirm",
    id_prefix       = "load_slot_confirm",
    prompt_key      = "load_data_here",
    prompt_fallback = "Continue from here?",
    yes_hook_fn     = "confirm_load_slot_yes",
    no_hook_fn      = "confirm_load_slot_no",
}

---------------------------------
--- remove_popup
---------------------------------
function M.remove_popup(gm) ConfirmPopup.remove_popup(gm, popup_args) end

--------------------------------
--- show_popup
--------------------------------
function M.show_popup(gm, slot_idx)
    popup_args.slot_idx = slot_idx
    popup_args.title_widget = TabDef.title_widget(slot_idx)
    ConfirmPopup.show_popup(gm, popup_args)
end

return M
