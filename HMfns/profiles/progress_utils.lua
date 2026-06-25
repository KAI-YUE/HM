local TabUtils = require("HMfns.utils.table_utils")

local deep_copy = TabUtils.deep_copy
local contains  = TabUtils.contains

local template = { tally = 0, of = 0 }
local Y, N = true, false 

local progress_utils = {}

--------------------------------------------------------
--- Set the progress 
--------------------------------------------------------
function progress_utils.set_progress(gm)
    local p_items = { "joker_stickers", "deck_stakes", "challenges" } 
    gm.PROGRESS = gm.PROGRESS or {};        local Pro   = gm.PROGRESS     

    for _, v in ipairs(p_items) do Pro[v] = deep_copy(template) end

    local POOLS, Ch, P, SET, Fs = gm.P_CPools, gm.CHALLENGES, gm.g_profile, gm.SET, gm.Fs
    local Pds, Pjs, Pch, sp     = Pro.deck_stakes, Pro.joker_stickers, Pro.challenges, SET.profile
    local _stake, _sticker      = Fs.deck_max_win_stake, Fs.fetch_joker_win_sticker

	for _, v in pairs(Pro) do if type(v) == "table" then v.tally, v.of = 0, 0 end end

	local prof = P[sp];        local pprogress  = prof.progress
    for _, v in ipairs(p_items) do pprogress[v] = deep_copy(Pro[v]) end
end

-----------------------------------------------
--- Set discoveries 
------------------------------------------------
-- Helper: increment of & tally
local function _inc(dt, key, discovered)
    local item = dt[key]
    item.of = item.of + 1
    if discovered then item.tally = item.tally + 1 end
end

-- main: Increment set discovery tally
function progress_utils.set_discoveries(gm)
    local discover_elems = { "blinds", "tags", "jokers", "consumables", "tarots", "planets", "spectrals", "vouchers", "boosters", "editions", "backs", "total" }

    gm.DISCOVER_TALLIES = {};          local dt = gm.DISCOVER_TALLIES
    for _, v in ipairs(discover_elems) do dt[v] = deep_copy(template) end

    local total_collect   = { "Joker", "Edition", "Voucher", "Deck", "Booster" }
	for _, v in pairs(gm.CMod) do
		if v.omit then goto c_continue end

        local set, dis = v.set, v.discovered 
        if set and contains(total_collect, set) then _inc(dt, "total", dis) end
        if     set == "Joker"    then _inc(dt, "jokers", dis) 
        elseif set == "Deck"     then _inc(dt, "backs", v.unlocked) end
        if v.consumable          then _inc(dt, "consumables", dis)
        if     set == "Planet"   then _inc(dt, "planets", dis)
        elseif set == "Spectral" then _inc(dt, "spectrals", dis)
        elseif set == "Tarot"    then _inc(dt, "tarots", dis) end end
        if     set == "Voucher"  then _inc(dt, "vouchers", dis)
        elseif set == "Booster"  then _inc(dt, "boosters", dis)
        elseif set == "Edition"  then _inc(dt, "editions", dis) end
        ::c_continue::
    end

    local dtt, dtb, dttg = dt.total, dt.blinds, dt.tags
    
	-- update profile score & progress snapshot
    local Fs, SET, Pro  = gm.Fs, gm.SET, gm.g_profile
	local prof          = Pro[SET.profile]
    local h_scores      = prof.high_scores
	h_scores.collection = h_scores.collection or {}

    local coll          = h_scores.collection
	coll.amt, coll.tot  = dtt.tally, dtt.of

	prof.progress.discovered = deep_copy(dtt)
    Fs.handle_unlock_request(gm, { type = "discover_amount", amount = dtt.tally, planet_count = dt.planets.tally, tarot_count = dt.tarots.tally })
end

-----------------------------------------------------------
--- Log consumable usage 
----------------------------------------------------------
function progress_utils.log_consumable_usage(gm, card)
	if not card.config.center_key or not card.ability.consumable then gm:save_settings(); return end
    local cfg, gG, Pro   = card.config, gm.GAME, gm.g_profile
    local center, F, SET = cfg.template, gm.Fs, gm.SET

	local prof = Pro[SET.profile]
	if prof.consumable_usage[cfg.center_key] then prof.consumable_usage[cfg.center_key].count = prof.consumable_usage[cfg.center_key].count + 1
    else prof.consumable_usage[cfg.center_key] = { count = 1, order = center.order } end

	gG.consumable_usage = gG.consumable_usage or {}
	if gG.consumable_usage[cfg.center_key] then gG.consumable_usage[cfg.center_key].count = gG.consumable_usage[cfg.center_key].count + 1
    else gG.consumable_usage[cfg.center_key] = { count = 1, order = center.order, set = card.ability.set} end

	gG.consumable_usage_total = gG.consumable_usage_total or { tarot = 0, planet = 0, spectral = 0, tarot_planet = 0, all = 0 }
	
    local set, usage = center.set, gG.consumable_usage_total
    if     set == "Tarot"    then usage.tarot,  usage.tarot_planet = usage.tarot + 1, usage.tarot_planet + 1
	elseif set == "Planet"   then usage.planet, usage.tarot_planet = usage.planet + 1, usage.tarot_planet + 1
	elseif set == "Spectral" then usage.spectral = usage.spectral + 1 end
	usage.all = usage.all + 1

	if not center.discovered then F.register_card_discovery(gm, card) end 
    if set ~= "Tarot" and set ~= "Planet" then return gm:save_settings() end

    gm.E_MANAGER:enqueue_event({ func = function() gG.last_tarot_planet = cfg.center_key; return Y end })
    gm:save_settings()
end

----------------------------------------------------
--- Set voucher usage
----------------------------------------------------
function progress_utils.log_voucher_usage(gm, card)
    local ccfg = card.config;       local ckey = ccfg.center_key
    if not ckey or card.ability.set ~= 'Voucher' then return gm:save_settings() end
    
    local Prof, SET = gm.g_profile, gm.SET
    local usage = Prof[SET.profile].voucher_usage
    if usage[ckey] then usage[ckey].count = usage[ckey].count + 1
    else usage[ckey] = { count = 1, order = ccfg.template.order } end
	gm:save_settings()
end

return progress_utils
