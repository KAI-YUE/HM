local UI      = require("HMui.menu.data.pages._1_load_2_save_pages._2_save.save_confirm.ui_helpers")
local Backend = require("HMui.menu.data.pages._1_load_2_save_pages._2_save.save_confirm.backend")

local M = {}

---------------------------------------------------
--- show | save_slot 
---------------------------------------------------
function M.show(gm, slot_idx)     if gm.clear_prepared_save_slot_data then gm:clear_prepared_save_slot_data() end; if gm.prepare_save_slot_data then gm:prepare_save_slot_data(slot_idx) end; UI.show_popup(gm, slot_idx) end
function M.save_slot(gm, source)  local cfg = source and source.config; M.show(gm, cfg and (cfg.slot_idx or cfg.save_slot_id)) end

-------------------------------------------------
--- confirm save slot no
-------------------------------------------------
function M.confirm_save_slot_no(gm) Backend.cancel_confirm(gm) end

-------------------------------------------------
--- confirm save slot yes
-------------------------------------------------
function M.confirm(gm, slot_idx) Backend.confirm_save_slot(gm, slot_idx) end
function M.confirm_save_slot_yes(gm, source)
    local cfg = source and source.config
    M.confirm(gm, cfg and (cfg.slot_idx or cfg.save_slot_id))
end

M.refresh_save_slot_ui = UI.refresh_save_slot_ui

return M
