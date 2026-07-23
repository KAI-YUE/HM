local FileIO = require("core.io.fileio")

local unpickle = FileIO.unpickle
local Y = true

local M = {}

-----------------------------
--- latest slot helpers
----------------------------------
function M.install(GMgr)
--- Helper: debug latest save slot
function GMgr:_debug_latest_save_slot()
    if not (self.list_save_slot_summaries and self.load_save_slot) then return end
    local summaries, count = self:list_save_slot_summaries(), (self.SET.save_data and self.SET.save_data.slot_count) or 9
    local latest_i, latest_t
    for i = 1, count do
        local t = summaries[i] and not summaries[i].empty and tonumber(summaries[i].saved_at)
        if t and (not latest_t or t > latest_t) then latest_i, latest_t = i, t end
    end
    if not latest_i then return end
    return latest_i, self:load_save_slot(latest_i)
end

--- Helper: quick load data
function GMgr:_dt_load()
    local slot_idx, slot_data = self:_debug_latest_save_slot()
    if slot_data then
        local run_snapshot = slot_data.run or slot_data;     if not run_snapshot then return end
        self.SET.slot_idx, self.saved_game = slot_idx, run_snapshot
        if self.E_MANAGER then self.E_MANAGER:clear_queue() end
        return self:start_run({ savetext = run_snapshot, save_data = slot_data, silent_start = Y })
    end

    self.saved_game = unpickle(self:slot_save_path(self.SET.profile)) or unpickle(self.SET.profile .. "/" .. "save.hm")
    if self.saved_game and self.E_MANAGER then self.E_MANAGER:clear_queue() end
    if self.saved_game then self:start_run({ savetext = self.saved_game, silent_start = Y }) end
end
end

return M

