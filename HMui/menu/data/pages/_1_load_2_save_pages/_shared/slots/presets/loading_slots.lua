local SlotList = require("HMui.menu.data.pages._1_load_2_save_pages._shared.slots.slot_list")

local M = {}

--- Helper: load_slot_opts
local function load_slot_opts()  return { list_id = "load_slot_list", page_id_prefix = "load_page", slot_id_prefix = "load_slot", hook_fn = "load_slot" } end

------------------------------------------------------
--- child_widgets: return loading slots page structure
-------------------------------------------------------
function M.child_widgets(gm) return SlotList.child_widgets(gm, load_slot_opts()) end

return M
