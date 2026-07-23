local achievement_defs = require("HMfns.profiles.gallery.achm_data")
local Y, N  = true, false

local M = {}
----------------------------------------------------------------------
-- Initialize achievements from settings or Steam
----------------------------------------------------------------------
function M.init_achievements(gm)
	if not gm.Tachms then gm.Tachms = achievement_defs end
	if gm.F.no_achm then return end
    local A, SET, St = gm.Tachms, gm.SET, gm.STEAM

	-- Local achievements
	if not St then -- cuz settings are saved, so they are stored twice in gm
        SET.achms = SET.achms or {}
		for k, _ in pairs(SET.achms) do if A[k] then A[k].earned = Y end end
        return
	end
	
	if St.initial_fetch then return end   -- Steam achievements
    for _, v in pairs(A) do
        local success, achieved = St.userStats.getAchievement(v.steamid)
        if success then v.earned = not not achieved end
    end
    St.initial_fetch = Y
end

---------------------------------------------------------------------
--- Grant Achievement 
---------------------------------------------------------------------
-- Helper: steam achievements
local function _steam_achm(St, A)
    local ustat, code       = St.userStats, A[ach_name].steamid
    local success, achieved = ustat.getAchievement(code)
    
    if success and achieved then return end  -- early bail out
    St.send_control.update_queued = Y
    ustat.setAchievement(code)
end

-- Helper func: general in-game achievements
local function _achievement(gm, ach_name)
    if gm.g_state == gm.g_states.hand_played then return end

    local P, SET, A  = gm.g_profile, gm.SET, gm.Tachms 
    local FH, St     = gm.f_handler, gm.STEAM
    local _alert     = gm.Fs.enqueue_alert
    local achm_set   = N

    if P[SET.profile].all_unlocked then return end
    if gm.F.no_achm        then return end
    if not A               then M.init_achievements(gm) end
    
    local A = gm.Tachms
    SET.achms[ach_name] = Y
    gm:save_progress()
    
    if not A[ach_name] then return end  -- early bail out
    if not A[ach_name].earned then achm_set = Y; FH.force = Y end
    A[ach_name].earned = Y

    if St       then _steam_achm(St, A) end
    if achm_set then _alert(gm, ach_name) end
    return Y
end

-- Grant an achievement
function M.grant_achievements(gm, ach_name)
    local P, SET, EM, _a = gm.g_profile, gm.SET, gm.E_MANAGER, "achievement"
	if P[SET.profile].all_unlocked then return end
	EM:enqueue_event({ queue = _a, no_delete = Y, blockable = N, blocking = N, func = function() return _achievement(gm, ach_name) end })
end

return M 