require("HMEng.my_io.string_packer")
local FileIO = require("core.io.fileio")
local C = require("HMfns.animate.color.color_const")

local cy,  bg = C.GRAY, C.UI.BACKGROUND_INACTIVE
local cb, crd = C.BLUE, C.RED

local profile = {}

--- Determines if there is a valid save file to load and continue from title page.
function profile.can_continue(gm, e)
    local ecfg, SET = e.config, gm.SET
    local gp, sg    = SET.profile, gm.saved_game

    if not ecfg.func then return end   -- Only run once: after the first call, clear e.config.func
    local save_path = gm.slot_save_path and gm:slot_save_path(gp) or (gp .. "/save.hm")
    local savefile = love.filesystem.getInfo(save_path) or love.filesystem.getInfo(gp .. "/save.hm")
    local _can_continue = nil

    if not savefile then ecfg.color, ecfg.button, ecfg.func = bg, nil, nil; return end
    if not sg then sg = FileIO.unpickle(save_path) or FileIO.unpickle(gp .. "/save.hm") end
    if not sg.Ver then ecfg.color, ecfg.button, ecfg.func = bg, nil, nil; return end
    
    _can_continue, ecfg.func = true, nil
     return _can_continue
end

----------------------------------------------------
--- Can Load profile
----------------------------------------------------
function profile.can_load_profile(gm, e)
    local ecfg, C, SET = e.config, gm.C, gm.SET
	if SET.profile == gm.focused_profile then ecfg.color, ecfg.button = bg, nil; return end
    ecfg.color, ecfg.button = C.BLUE, "load_profile"
end

-----------------------------------------------------
--- Can delete_profile
---------------------------------------------------- 
function profile.can_delete_profile(gm, e)
    local ch_data = gm.CHECK_PROFILE_DATA
    if not ch_data then
        local shared = FileIO.unpickle(gm.shared_save_path and gm:shared_save_path() or "shared.hm")
        gm.CHECK_PROFILE_DATA = (shared and shared.profiles and shared.profiles[gm.focused_profile]) or love.filesystem.getInfo(gm.focused_profile .. "/profile.hm")
    end
    
    local ch_data, ecfg = gm.CHECK_PROFILE_DATA, e.config
	if not ch_data or ecfg.disable_button then gm.CHECK_PROFILE_DATA = false; ecfg.color, ecfg.button = bg, nil
    else ecfg.color, ecfg.button  = crd, "delete_profile" end
end

-----------------------------------------------
--- Can unlock_all
----------------------------------------------
function profile.can_unlock_all(gm, e)
    local ecfg, _P = e.config, gm.g_profile[gm.SET.profile]
	if _P.all_unlocked or ecfg.disable_button then ecfg.color, ecfg.button = bg, nil; return end
	ecfg.color, ecfg.button = cy, "unlock_all"
end

return profile
