local SlotList = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.slot_list")

local M = {}

--- Helper: save_slot_opts
local function save_slot_opts()  return { list_id = "save_slot_list", page_id_prefix = "save_page", slot_id_prefix = "save_slot", hook_fn = "save_slot", primary_hint_i18n_key = "save", primary_on_empty = true } end

-----------------------------------------------------
--- child_widgets: return saving slots page structure
-----------------------------------------------------
function M.child_widgets(gm) return SlotList.child_widgets(gm, save_slot_opts()) end

return M
