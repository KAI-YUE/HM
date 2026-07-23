require "love.filesystem"
require "HMEng.my_io.string_packer"

local FileIO  = require("core.io.fileio")
local LF      = love.filesystem

local pickle_dump = FileIO.pickle_dump

local Y, N = true, false

local SaveUtils = {}

---------------------------------------------------------------------------------------
--- shared_path | save_root | slot_root | slot_path | slot_meta_path
---------------------------------------------------------------------------------------
function SaveUtils.shared_path(save_data)           return (save_data and save_data.shared) or "shared.hm" end
function SaveUtils.save_root(save_data)             return (save_data and save_data.root) or "saves" end
function SaveUtils.slot_root(save_data)             return (save_data and save_data.slots_root) or (SaveUtils.save_root(save_data) .. "/slots") end
function SaveUtils.slot_path(save_data, slot)       return ("%s/slot_%02d.hm"):format(SaveUtils.slot_root(save_data), slot or 1) end
function SaveUtils.slot_meta_path(save_data, slot)  return ("%s/slot_%02d_meta.hm"):format(SaveUtils.slot_root(save_data), slot or 1) end

-------------------------------------------------------------------
--- request_slot_idx
-------------------------------------------------------------------
function SaveUtils.request_slot_idx(request)
    local sp   = request and request.save_progress
    local SET  = sp and sp.SET or {}
    return request.slot_idx or request.slot_id or (sp and (sp.slot_idx or sp.slot_id)) or SET.slot_idx or 1
end

-------------------------------------------------------------------
--- ensure_slot_dir
-------------------------------------------------------------------
function SaveUtils.ensure_slot_dir(save_data)
    local root   = SaveUtils.save_root(save_data)
    local slots  = SaveUtils.slot_root(save_data)
    if not LF.getInfo(root)  then LF.createDirectory(root) end
    if not LF.getInfo(slots) then LF.createDirectory(slots) end
end

-------------------------------------------------------------------
--- load_shared
-------------------------------------------------------------------
function SaveUtils.load_shared(save_data)
    local path = SaveUtils.shared_path(save_data);      if not LF.getInfo(path) then return { profiles = {}, meta = {}, unlock_notify = {} } end

    local shared = FileIO.unpickle(path) or {}
    shared.profiles       = shared.profiles or {}
    shared.meta           = shared.meta or {}
    shared.unlock_notify  = shared.unlock_notify or {}
    return shared
end

-------------------------------------------------------------------
--- save_shared | load_unlock_notify
-------------------------------------------------------------------
function SaveUtils.save_shared(save_data, shared)         FileIO.pickle_dump(SaveUtils.shared_path(save_data), shared) end
function SaveUtils.load_unlock_notify(save_data, profile) local shared = SaveUtils.load_shared(save_data); return shared, shared.unlock_notify[profile] or get_compressed(profile .. "/unlock_notify.hm") or ""; end

-------------------------------------------------------------------
--- update_meta_state
-------------------------------------------------------------------
function SaveUtils.update_meta_state(meta, uda)
    local changed = N
    for k, v in pairs(uda) do
        if v:find("u") and not meta.unlocked[k]   then meta.unlocked[k] = Y;   changed = Y   end
        if v:find("d") and not meta.discovered[k] then meta.discovered[k] = Y; changed = Y end
        if v:find("a") and not meta.alerted[k]    then meta.alerted[k] = Y;    changed = Y end
    end
    return changed
end

--------------------------------------------------------------------
--- preserve_slot_progress_meta
--------------------------------------------------------------------
function SaveUtils.preserve_slot_progress_meta(save_data, slot_id, meta)
    local old_meta = FileIO.unpickle(SaveUtils.slot_meta_path(save_data, slot_id));     if not old_meta then return meta end
    meta.unlocked   = meta.unlocked   or old_meta.unlocked
    meta.discovered = meta.discovered or old_meta.discovered
    meta.alerted    = meta.alerted    or old_meta.alerted
    return meta
end

---------------------------------------------------------------------
--- handle_save_progress
---------------------------------------------------------------------
function SaveUtils.handle_save_progress(request, ch)
    local SET        = request.save_progress.SET
    local slot_idx   = SaveUtils.request_slot_idx(request)
    local save_data  = SET.save_data

    SaveUtils.ensure_slot_dir(save_data)
    local meta       = FileIO.unpickle(SaveUtils.slot_meta_path(save_data, slot_idx)) or { slot_id = slot_idx }
    meta.unlocked    = meta.unlocked or {}
    meta.discovered  = meta.discovered or {}
    meta.alerted     = meta.alerted or {}

    SaveUtils.update_meta_state(meta, request.save_progress.progress_flags)
    pickle_dump(SaveUtils.slot_meta_path(save_data, slot_idx), meta)

    ch:push("done")
end

-----------------------------------------------------------
--- handle_save_settings
-----------------------------------------------------------
function SaveUtils.handle_save_settings(request)
    local save_data  = request.save_data or request.save_settings.save_data
    local profile    = request.profile_num or 1
    local shared     = SaveUtils.load_shared(save_data)
    shared.settings  = request.save_settings
    shared.profiles[profile] = request.save_profile
    SaveUtils.save_shared(save_data, shared)
end

-------------------------------------------------------------
--- handle_save_metrics
-------------------------------------------------------------
function SaveUtils.handle_save_metrics(request) pickle_dump("metrics.hm", request.save_metrics) end

------------------------------------------------------------
--- handle_save_notify
------------------------------------------------------------
function SaveUtils.handle_save_notify(request)
    local save_data  = request.save_data
    local profile    = request.profile_num or 1
    local shared, unlock_notify = SaveUtils.load_unlock_notify(save_data, profile)
    if not request.save_notify or unlock_notify:find(request.save_notify) then return end 
    shared.unlock_notify[profile] = unlock_notify .. request.save_notify .. "\n"
    SaveUtils.save_shared(save_data, shared)
end

-------------------------------------------------------------
--- handle_save_run
-------------------------------------------------------------
function SaveUtils.handle_save_run(request)
    local save_data  = request.save_data
    local slot_id    = request.slot_id or request.profile_num
    SaveUtils.ensure_slot_dir(save_data)
    pickle_dump(SaveUtils.slot_path(save_data, slot_id), request.save_table)
    if request.save_meta then pickle_dump(SaveUtils.slot_meta_path(save_data, slot_id), SaveUtils.preserve_slot_progress_meta(save_data, slot_id, request.save_meta)) end
end

return SaveUtils
