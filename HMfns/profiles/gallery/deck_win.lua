local deck_utils = {}

------------------------------------------------
--- Deck usage
------------------------------------------------
function deck_utils.inc_deck_usage(gm)
    local game = gm.GAME
	local sel  = game.selected_back
    -- early bail out
    if not sel then return end 
    local effect = sel.effect;     if not effect then return end
    local center = effect.template;  if not center then return end
    local key    = center.key;     if not key    then return end

    local P, SET     = gm.g_profile, gm.SET
    local usage      = P[SET.profile].deck_usage
    local default    = { count = 0, order = center.order, wins = {}, losses = {} }
    usage[key]       = usage[key] or default 
    usage[key].count = usage[key].count + 1
    if gm.save_settings then gm:save_settings() end
end

------------------------------------------------
--- Deck wins
------------------------------------------------
function deck_utils.inc_deck_win(gm)
    local game = gm.GAME
	local sel  = game.selected_back
    -- early bail out
    if not sel then return end 
    local effect = sel.effect;     if not effect then return end
    local center = effect.template;  if not center then return end
    local key    = center.key;     if not key    then return end

    local P, SET   = gm.g_profile, gm.SET
    local usage, s = P[SET.profile].deck_usage, game.stake
    local default  = { count = 1, order = center.order, wins = {}, losses = {} }
    usage[key]     = usage[key] or default
    usage[key].wins[s] = (usage[key].wins[s] or 0) + 1
    
    set_challenge_unlock()
    if gm.save_settings then gm:save_settings() end
end

------------------------------------------------
--- Deck loss
------------------------------------------------
function deck_utils.inc_deck_loss(gm)
    local game = gm.GAME
	local sel  = game.selected_back
    -- early bail out
    if not sel then return end 
    local effect = sel.effect;     if not effect then return end
    local center = effect.template;  if not center then return end
    local key    = center.key;     if not key    then return end

    local P, SET   = gm.g_profile, gm.SET
    local usage, s = P[SET.profile].deck_usage, game.stake
    local default  = { count = 1, order = center.order, wins = {}, losses = {} }
    usage[key]     = usage[key] or default
    usage[key].losses[s] = (usage[key].losses[s] or 0) + 1
    if gm.save_settings then gm:save_settings() end
end

----------------------------------------------------
--- Deck win stake 
----------------------------------------------------
--- Helper: when the key is not given 
local function _default_win_stake(usage)
    local deck_count, w, w_low = 0, 0, nil
    local _max, _min = math.max, math.min
    for _, deck in pairs(usage) do
        local won = false
        for k in pairs(deck.wins or {}) do won = true; w = _max(k, w) end
        if won then deck_count = deck_count + 1 end
        w_low = w_low and _min(w_low, w) or w
    end

    return w
end

--- Main: get deck win stake 
function deck_utils.deck_max_win_stake(gm, key)
    local P, SET     = gm.g_profile, gm.SET
    local usage, w  = P[SET.profile].deck_usage, 0

	if not key then return _default_win_stake(usage) end -- not sure if this func will be called 

	local ud = usage[key]
	if not ud or not ud.wins then return 0 end

    for k in pairs(ud.wins) do w = math.max(k, w) end
    return w
end

----------------------------------------------------
--- Deck win sticker
----------------------------------------------------
function deck_utils.fetch_deck_win_sticker(gm, _center)
    local P, SET    = gm.g_profile, gm.SET
	local w, usage  = 0, P[SET.profile].deck_usage[_center.key]

	if not usage or not usage.wins then return end
    for k in pairs(usage.wins) do w = math.max(k, w) end
    if w > 0 then return gm.sticker_map[w] end
    return 0
end


return deck_utils
