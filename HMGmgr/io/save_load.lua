local FileIO   = require("core.io.fileio")
local pro_data = require("HMGmgr.data.temp_profile")

local unpickle = FileIO.unpickle

local Y, N = true, false

local TUDA = { "CMod" }

return function (GMgr)
-----------------------------
--- Shared save paths
----------------------------------
function GMgr:shared_save_path() return (self.SET.save_data and self.SET.save_data.shared) or "shared.hm" end

function GMgr:slot_save_path(slot)
    local SD = self.SET.save_data or {}
    return ("%s/slot_%02d.hm"):format(SD.slots_root or ((SD.root or "saves") .. "/slots"), slot or self.SET.slot_idx or 1)
end

-----------------------------
--- Update file handler 
----------------------------------
function GMgr:_update_file_handler(force) local _FH = self.f_handler; _FH.settings, _FH.update_queued = Y, Y; if force then _FH.force = Y end  end
function GMgr:_progress_file_handler()    local _FH = self.f_handler; _FH.progress, _FH.update_queued = Y, Y end
function GMgr:_run_file_handler()         local _FH = self.f_handler; _FH.run, _FH.update_queued = Y, Y end

-----------------------------
--- Save Settings 
----------------------------------
function GMgr:save_settings(force)
    self.args.save_settings = self.SET
    self:_update_file_handler(force)
    if force and self.update_save_dat then self:update_save_dat() end
end

-----------------------------
--- Save progress 
----------------------------------
--- Helper: _s_progress
function GMgr:_s_progress()
    local args, SET, _P, F = self.args, self.SET, self.g_profile, self.Fs
    args.save_progress = args.save_progress or {}
    
    local sp = args.save_progress;                 sp.progress_flags = F.wipe(sp.progress_flags)
    sp.SET, sp.slot_idx = SET, SET.slot_idx or args.save_slot_id or 1;     local progress_flags = sp.progress_flags

    for _, _uda in ipairs(TUDA) do for k, v in pairs(self[_uda]) do progress_flags[k] = (v.unlocked and "u" or "")..(v.discovered and "d" or "")..(v.alerted and "a" or "") end  end
    self:_progress_file_handler()
    return Y
end

function GMgr:save_progress()
    local EM = self.E_MANAGER
    if not EM then return self:_s_progress() end
    EM:enqueue_event({ func = function () return self:_s_progress() end }) 
end

-----------------------------
--- Load profile 
----------------------------------
--- Helper: recursive_init
local function recursive_init (t1, t2) for k, v in pairs(t1) do if not t2[k] then  t2[k] = v elseif type(t2[k]) == "table" and type(v) == "table" then recursive_init(v, t2[k]) end end end

function GMgr:load_profile(_profile)
    if not self.g_profile[_profile] then _profile = 1 end

    local SET = self.SET;          SET.profile = _profile

    local shared = unpickle(self:shared_save_path())
    local info = shared and shared.profiles and shared.profiles[_profile] or unpickle(_profile.."/profile.hm")
    if info then for k, v in pairs(info) do self.g_profile[_profile][k] = v end end

    local temp_profile = pro_data.tmp_profile()
    recursive_init(temp_profile, self.g_profile[_profile])
end

-----------------------------
--- Save notify 
----------------------------------
function GMgr:save_notify(card) self.SaveMgr.channel:push({ type = "save_notify", save_notify = card.key, profile_num = self.SET.profile, save_data = self.SET.save_data }) end

end
