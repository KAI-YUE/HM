local joker_utils = {}

-----------------------------------------------
--- Retrieve joker 
----------------------------------------------
--- Helper: determines if this is the joker we want 
local function _the_joker(v, name, non_debuff)
    if not v or type(v) ~= "table"     then return false end
	if not v.ability or v.ability.name ~= name then return false end
    if not non_debuff and v.debuff  then return false end
    return true
end

--- main: retrieve THE joker 
function joker_utils.retrieve_joker(gm, name, non_debuff)
	local jokers = {}
	local gj     = gm.jokers
    if not (gj and gj.cards) then return joker end

	for _, v in pairs(gj.cards) do
        if not _the_joker(v, name, non_debuff) then goto continue end
        jokers[#jokers+1] = v
        ::continue::
	end

    local c = gm.consumables.cards or {}
	for _, v in pairs(c) do
		if not _the_joker(v, name, non_debuff) then goto continue end
		jokers[#jokers+1] = v
		::continue::
	end
	return jokers
end

--------------------------------------------
--- Inc joker usage
--------------------------------------------
--- Helper: determines if the ability.set is Joker
local function _the_card(v)
    if not v.config or not v.config.center_key   then return false end
    if not v.ability or v.ability.set ~= "Joker" then return false end
    return true
end

function joker_utils.inc_joker_usage(gm)
    local P, SET  = gm.g_profile, gm.SET
    local c       = gm.jokers.cards or {}
	for _, v in pairs(c) do
		if not _the_card(v) then goto continue end
        local usage    = P[SET.profile].joker_usage
        local vcfg     = v.config
        local key, o   = vcfg.center_key, vcfg.template.order
        local template = {count = 0, order = o, wins = {}, losses = {}}

        usage[key] = usage[key] or template 
        usage[key].count = usage[key].count + 1
        ::continue::
    end
	if gm.save_settings then gm:save_settings() end
end

--- Main: joker win
function joker_utils.inc_joker_win(gm)
    local P, SET  = gm.g_profile, gm.SET
    local game, c = gm.GAME, gm.jokers.cards or {}
	for _, v in pairs(c) do
		if not _the_card(v) then goto continue end
        local usage  = P[SET.profile].joker_usage
        local vcfg   = v.config
        local key, o = vcfg.center_key, vcfg.template.order
        local s      = game.stake
        local template = {count = 1, order = o, wins = {}, losses = {}}

        usage[key] = usage[key] or template
        usage[key].wins = usage[key].wins or {}
        usage[key].wins[s] = (usage[key].wins[s] or 0) + 1
        ::continue::
    end
	if gm.save_settings then gm:save_settings() end
end

------------------------------------------------
--- Joker win sticker 
------------------------------------------------
function joker_utils.fetch_joker_win_sticker(gm, _center, index)
    local P, SET    = gm.g_profile, gm.SET
	local _w, usage = 0, P[SET.profile].joker_usage[_center.key]
    
	if not usage or not usage.wins then return 0 end
    for k in pairs(usage.wins) do _w = math.max(k, _w) end
    if index then return _w end
    if _w > 0 then return gm.sticker_map[_w] end
	return 0
end

function joker_utils.set_joker_loss(gm)
	for _, v in pairs(gm.jokers.cards or {}) do
		if v.config and v.config.center_key and v.ability and v.ability.set == "Joker" then
			local usage = gm.g_profile[gm.SET.profile].joker_usage
			usage[v.config.center_key] = usage[v.config.center_key] or {count = 1, order = v.config.template.order, wins = {}, losses = {}}
			usage[v.config.center_key].losses = usage[v.config.center_key].losses or {}
			usage[v.config.center_key].losses[gm.GAME.stake] = (usage[v.config.center_key].losses[gm.GAME.stake] or 0) + 1
		end
	end
	if gm.save_settings then gm:save_settings() end
end

return joker_utils
