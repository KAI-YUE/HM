local ConfirmPopup = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")
local SlotTextFx = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.textfx")

local Y, N = true, false

local M = {}

--- Helper: slot_title_textfx
local function slot_title_textfx(slot_idx, panel_w)
    return {
        --- basic settings
        style     = "text_widget",      id            = "save_slot_confirm_title",  
        paint_bg  = N,                  text_overlay  = N,                          
        shadow    = N,

        --- textfx settings
        T       = { x = 0, y = 0.68, w = panel_w, h = 0.8 },
        textfx  = SlotTextFx.title_textfx(slot_idx, { x = 0, y = 0.12, w = panel_w, h = 0.4 }, { text_scale = 0.7, text_align = { x = "center", y = "middle" } }),
    }
end

--- Helper: title_widget
function M.title_widget(slot_idx) return function(panel_w) return slot_title_textfx(slot_idx, panel_w) end end


return M
