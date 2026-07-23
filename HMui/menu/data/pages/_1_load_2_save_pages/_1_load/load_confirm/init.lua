local UI      = require("HMui.menu.data.pages._1_load_2_save_pages._1_load.load_confirm.ui_helpers")
local Backend = require("HMui.menu.data.pages._1_load_2_save_pages._1_load.load_confirm.backend")

local M = {}

---------------------------------------------------
--- show | load_slot 
---------------------------------------------------
function M.show(gm, slot_idx) UI.show_popup(gm, slot_idx) end
function M.load_slot(gm, source)
    local cfg = source and source.config;      if not cfg or not cfg.save_slot_meta or cfg.save_slot_meta.empty then return end
    M.show(gm, cfg and (cfg.slot_idx or cfg.save_slot_id))
end

-------------------------------------------------
--- confirm load slot no
-------------------------------------------------
function M.confirm_load_slot_no(gm) Backend.cancel_confirm(gm) end

-------------------------------------------------
--- confirm load slot yes
-------------------------------------------------
function M.confirm(gm, slot_idx) Backend.confirm_load_slot(gm, slot_idx) end
function M.confirm_load_slot_yes(gm, source)
    local cfg = source and source.config
    M.confirm(gm, cfg and (cfg.slot_idx or cfg.save_slot_id))
end

return M
