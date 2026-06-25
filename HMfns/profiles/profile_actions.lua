-- local UIPanel     = require("HMEng.ui_actors.ui_panel")    = require("HMEng.ui_actors.ui_panel")
local SoundUtils = require("HMfns.utils.sound_utils")
local FileIO     = require("core.io.fileio")
local play_clip  = SoundUtils.play_clip
local Y, N = true, false

local M = {}

--------------------------------------------------
--- Load Profile 
--------------------------------------------------
-- Helper: delete and init
local function _delete_and_init(gm, delete)
    local P, fp = gm.g_profile, gm.focused_profile
    local _name = nil
    gm:delete_run()
    
    if P[fp].name and P[fp].name ~= "" then _name = P[fp].name end
    if delete then P[fp] = {} end
    
    gm.DISCOVER_TALLIES, gm.PROGRESS = nil, nil
    gm:load_profile(fp)
    P[fp].name = _name
    gm:init_item_prototypes()
    return Y
end

-- Helper: open title page 
local function _title_page(gm) gm:title_page(); gm.f_handler.force = Y; return Y end

---______________________________________________
--- Main: load_profile
---______________________________________________
function M.load_profile(gm, delete_prof_data)
    local EM, Fs       = gm.E_MANAGER, gm.Fs
    local swipe, fwipe = Fs.start_wipe_fx, Fs.finish_wipe_fx

	gm.saved_game = nil
	EM:clear_queue()
	-- swipe(gm)

	EM:enqueue_event({ no_delete = Y, func = function() return _delete_and_init(gm, delete_prof_data) end })
	EM:enqueue_event({ no_delete = Y, blockable = Y, blocking = N, func = function() return _title_page(gm) end })
	-- fwipe(gm)
end

--------------------------------------------------
--- delete Profile
--------------------------------------------------
--- Helper funcs
local function _tarot(gm)      play_clip(gm, "tarot2", 0.76, 0.4); return Y end
local function _enable_btn(ec) ec.disable_button = nil; return Y end

--- Helper: warning state 
local function _delete_state(gm, EM, text, tcfg, ecfg)
    text:jitter_me()
    tcfg.color, tcfg.shadow, ecfg.disable_button = gm.C.WHITE, Y, Y

    -- Quick juice + reset disable
    EM:enqueue_event({ trigger = "after", delay = 0.06, func = function() return _tarot(gm) end })
    EM:enqueue_event({ trigger = "after", delay = 0.35, func = function() return _enable_btn(ecfg) end })
    play_clip(gm, "tarot2", 1, 0.4)
end

--- Main: execute the deletion of the profile
function M.delete_profile(gm, e)
    local EM, OM, P, C = gm.E_MANAGER, gm.UI.overlay_menu, gm.g_profile, gm.C
	local text, fp     = e.UIPanel:get_UI_by_ID("warning_text"), gm.focused_profile
    local tcfg, ecfg   = text.config, e.config

	if tcfg.color ~= C.WHITE then return _delete_state(gm, EM, text, tcfg, ecfg) end

	-- Delete profile files + reset state
    local data_dict = { "/profile.hm", "/save.hm", "/meta.hm", "/unlock_notify.hm", "" }
    for _, v in ipairs(data_dict) do love.filesystem.remove(fp .. v) end
    if gm.slot_save_path then love.filesystem.remove(gm:slot_save_path(fp)) end
    
    if gm.shared_save_path then
        local shared = FileIO.unpickle(gm:shared_save_path()) or {}
        if shared.profiles      then shared.profiles[fp] = nil end
        if shared.meta          then shared.meta[fp] = nil end
        if shared.unlock_notify then shared.unlock_notify[fp] = nil end
        FileIO.pickle_dump(gm:shared_save_path(), shared)
    end

	gm.saved_game, gm.DISCOVER_TALLIES = nil, nil
	gm.PROGRESS,   P[fp]               = nil, {}

	if fp == gm.SET.profile then M.load_profile(gm, Y)
    else local tab_but = OM:get_UI_by_ID("tab_but_" .. fp); gm.Fs.set_active_tab(gm, tab_but) end
end

--------------------------------------------------
--- Unlock all 
--------------------------------------------------
--- Helper: warning state 
local function unlock_warning(gm, EM, icfg, ecfg, infotip)
    local Fs, text    = gm.Fs, "ml_unlock_all_explanation"
    local iobj, _info = icfg.object, Fs.info_layout
    -- local iobj, _info = icfg.object, Fs.info_popup_layout
    local i18n        = Fs.i18n 
    iobj:remove()

    local _warn_txt =  i18n(gm, text) 
    local offset, _def = { x = 0, y = 0 }, _info(_warn_txt)

    local panel = UIPanel(gm, { definition = _info(gm, i18n(gm, text)), config = { offset = offset, align = "bm", parent = infotip } })
    icfg.object = panel
    icfg.object.UIRoot:jitter_me()

    icfg.set, ecfg.disable_button = Y, Y
    EM:enqueue_event({ trigger = "after", delay = 0.06, func = function() return _tarot(gm) end })
    EM:enqueue_event({ trigger = "after", delay = 0.35, func = function() return _enable_btn(ecfg) end })
    play_clip(gm, "tarot2", 1, 0.4)
end

--- Helper: set unlock in the group to be true
local function unlock_group(group)
    for _, v in pairs(group) do
        if v.demo or v.wip then goto continue end
        v.alerted, v.discovered, v.unlocked = Y, Y, Y
        ::continue::
    end
end

--______________________________________________
--- Main: execute the action of unlocking all 
--_______________________________________________
function M.unlock_all(gm, e)
    local EM, OM, Fs  = gm.E_MANAGER, gm.UI.overlay_menu, gm.Fs
	local P, infotip  = gm.g_profile, OM:get_UI_by_ID("info_menu")
    local icfg, ecfg  = infotip.config, e.config

	-- Show warning before unlocking
	if not icfg.set and not gm.F.no_achm then return unlock_warning(gm, EM, icfg, ecfg, infotip) end
	
    -- Unlock everything
	P[gm.SET.profile].all_unlocked = Y
    local unlock_sets = { "CMod", "P_BLINDS", "P_TAGS" }
    for _, v in ipairs(unlock_sets) do unlock_group(gm[v]) end

	Fs.set_progress(gm)
    Fs.set_discoveries(gm)
	gm:save_progress()
	gm.f_handler.force = Y

	local tab_but = gm.UI.overlay_menu:get_UI_by_ID("tab_but_" .. gm.focused_profile)
	Fs.set_active_tab(gm, tab_but)
end


return M
