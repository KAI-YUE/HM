local UI      = require("HMui.menu.data.pages._1_load_2_save_pages._shared.delete_confirm.ui_helpers")
local Backend = require("HMui.menu.data.pages._1_load_2_save_pages._shared.delete_confirm.backend")

local Y, N = true, false

local M = {}

--------------------------------------------------
--- Main: open delete confirmation
--------------------------------------------------
function M.delete_save_slot(gm, source)
    local cfg = source and source.config
    if not (cfg and cfg.save_slot_meta and not cfg.save_slot_meta.empty) then return N end
    UI.show_popup(gm, cfg.slot_idx or cfg.save_slot_id)
    return Y
end

--------------------------------------------------
--- Main: cancel delete confirmation
--------------------------------------------------
function M.confirm_delete_slot_no(gm) Backend.cancel_confirm(gm) end

--------------------------------------------------
--- Main: confirm delete
--------------------------------------------------
function M.confirm_delete_slot_yes(gm, source)
    local cfg = source and source.config
    return Backend.confirm_delete_slot(gm, cfg and (cfg.slot_idx or cfg.save_slot_id))
end

return M
