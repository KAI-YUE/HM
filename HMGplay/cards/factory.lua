local TabUtils   = require("HMfns.utils.table_utils")
local RNG, POOLS = require("HMfns.utils.math.rng_utils"), require("HMGplay.cards.card_pools")
local Meshi      = require("HMGplay.cards.card_data.meshi")
local Machi      = require("HMGplay.cards.card_data.machi")
local Rranks     = require("HMGplay.cards.card_data.hand_ranks")

local Rrlabels   = Rranks.rank_labels
local seeded_rand, _hash = RNG.seeded_random, RNG.hash_unit32
local fetch_pool         = POOLS.fetch_current_pool 
local contains, _pick    = TabUtils.contains, TabUtils.random_pick
local deep_copy, push    = TabUtils.deep_copy, table.insert

local max, min = math.max, math.min

local Y, N  = true, false

local Tspecial = { meshi = Meshi, machi = Machi }
local M = {}
------------------------------------
--- spawn card 
------------------------------------
-- Helper: build_discovery_flags
local function build_discovery_flags(gm, zone) end

--____________________________________________
--- Main 
--____________________________________________
function M.spawn_card(gm, _type, zone, legendary, rarity, skip_materialize, soul, forced_key, key_append)
	local gG, _PC, F   = gm.GAME, gm.CMod, gm.Fs
    local zone, center = zone or gm.jokers, _PC.b_red
	local bk, Gmod     = gG.banned_keys, gG.modifiers

	if _type == "Base" then forced_key = "c_base" end           -- Base card override
	if forced_key and not bk[forced_key] then center = _PC[forced_key]; _type = (center.set ~= "Default" and center.set or _type)
	else
		local _pool, _pool_key = fetch_pool(gm, _type, rarity, legendary, key_append)
		center = _pick(_pool, _hash(gm, "spawn".._pool_key));    local it = 1
		while center == "UNAVAILABLE" do it = it + 1; center =  _pick(_pool, _hash(gm, "spawn")) end
		center = _PC[center]
	end

	local front = (_type == "Base" or _type == "Enhanced") and  _pick(gm.P_CARDS, _hash(gm, "spawn"))  -- Visual front
	local aT, CW, CH = zone.T, gm.card_w, gm.card_h
    local ax, ay, aw = aT.x, aT.y, aT.w
    
    local Card = require("HMEng.entities.card")
	local card = Card(gm, ax + aw/2, ay, CW, CH, front, center, build_discovery_flags(gm, zone))  -- Spawn card
	
    if card.ability.consumable and not skip_materialize then card:start_materialize() end
end

-----------------------------------------------------------
--- Spawn playing_cards
-----------------------------------------------------------
function M.spawn_playing_cards(gm, card_init, zone, skip_materialize, silent, colors)
    card_init = card_init or {}
    card_init.front  = card_init.front  or _pick(gm.P_CARDS, _hash(gm, "front"))
    card_init.template = card_init.template or gm.CMod.c_base
    gm.playing_card  = (gm.playing_card and gm.playing_card + 1) or 1
    
    local zone, Card = zone or gm.hand, require("HMEng.entities.card")
    local aT, W, H = zone.T, gm.card_w, gm.card_h
    
    local card = Card(gm, aT.x, aT.y, W, H, card_init.front, card_init.template, { playing_card = gm.playing_card })
    push(gm.run_card_id, card)
    card.playing_card = gm.playing_card

    if zone then zone:emplace(card) end
    if not skip_materialize then card:start_materialize(colors, silent) end

    return card
end

-----------------------------------------------------------
--- Spawn special_card
-----------------------------------------------------------
-- Helper: weighted_pick
local function _weighted_pick(t, weight_key)
    local total = 0
    for _, v in ipairs(t or {}) do total = total + max(0, tonumber(v[weight_key or "weight"]) or 0) end
    if total <= 0 then return deep_copy((t or {})[1]) end

    local roll, acc = math.random() * total, 0
    for _, v in ipairs(t) do
        acc = acc + max(0, tonumber(v[weight_key or "weight"]) or 0)
        if roll <= acc then return deep_copy(v) end
    end

    return deep_copy(t[#t])
end

-- Helper: normalize_special_rank
local function _normalize_special_rank(rank_data)
    if type(rank_data) == "table" then return deep_copy(rank_data) end
    if rank_data == nil then return {} end

    local rank = tostring(rank_data)
    return { rank = rank, rank_label = rank, value = Rranks.values[rank] }
end

-- Helper: random_special_rank
local function _random_special_rank()
    local rank = tostring(_pick(Rrlabels))
    return _normalize_special_rank(rank)
end

-- Helper: resolve_special_suit
local function _resolve_special_suit(def, args)
    if args.s or args.suit then return args.s or args.suit end

    local rules = def.rules or {}
    local suits = def.options and def.options.suits or {}
    if not suits[1] then return end
    if rules.random_suit == Y then return _pick(suits) end
    return suits[1]
end

-- Helper: resolve_special_rank
local function _resolve_special_rank(def, args)
    if args.rank_data then return _normalize_special_rank(args.rank_data) end

    local rules, ranks   = def.rules or {}, def.options and def.options.ranks 
    if rules.random_rank and (not ranks) then return _random_special_rank() end

    local wanted_rank = args.r or args.rank
    if not ranks[1] then return {} end
    if wanted_rank then
        for _, rank_data in ipairs(ranks) do
            local resolved = _normalize_special_rank(rank_data)
            if tostring(resolved.rank) == tostring(wanted_rank) then return resolved end
        end
    end

    if rules.random_rank == Y then return _normalize_special_rank(_weighted_pick(ranks, "weight")) end
    return _normalize_special_rank(ranks[1])
end

--_______________________________
-- main: spawn_special_card
--_______________________________
function M.spawn_special_card(def, card_key, args)
    local base      = deep_copy(def.base or {})
    local suit      = _resolve_special_suit(def, args)
    local rank_data = _resolve_special_rank(def, args)
    local rank      = rank_data.rank or args.r or args.rank

    base.suit,  base.rank         = suit, tostring(rank)
    base.value, base.rank_label   = rank_data.value or base.value, rank_data.rank_label or base.rank_label or base.rank
    base.name,  base.special_key  = base.name or (base.rank.."of"..base.suit), card_key
    return base
end

-----------------------------
-- fetch_special_card_def
-----------------------------
function M.fetch_special_card_def(card_set, card_key) local set = Tspecial[card_set]; return set and set[card_key] end

--------------------------------
--- Clone a card
--------------------------------
function M.clone_card(gm, other, new_card, scale, playing_card, strip_edition)
    local Card, _s  = require("HMEng.entities.card"), scale or 1
    local W, H, oT  = _s*gm.card_w, _s*gm.card_h, other.T

	new_card = new_card or Card(gm, oT.x, oT.y, W, H, gm.P_CARDS.empty, gm.CMod.c_base, { playing_card = playing_card })

    local ocfg, oab = other.config, other.ability;  new_card:set_ability(ocfg.template)
	new_card.ability.type = oab.type;           	new_card:set_base(ocfg.card)

	for k, v in pairs(oab) do new_card.ability[k] = (type(v) == "table") and deep_copy(v) or v end
	if not strip_edition then new_card:set_edition(other.edition or {}, nil, true) end
	gm.Fs.handle_unlock_request(gm, { type = "have_edition" })

	new_card:set_seal(other.seal, Y)

	if other.params then new_card.params = other.params; new_card.params.playing_card = playing_card end
	new_card.debuff, new_card.pinned = other.debuff, other.pinned
	return new_card
end

-------------------------------------------------------------------
--- Roll Card edition
-------------------------------------------------------------------
function M.roll_edition(gm, _mod, _no_neg, _guaranteed)
    local _mod, rate   = _mod or 1, gm.GAME.edition_rate
    local digest       = seeded_rand(gm, ("edition %.2f").format(rate))
    if _guaranteed then
        if     digest > 0.925 and not _no_neg then return { negative = Y }
        elseif digest > 0.85 then return { polychrome = Y }
        elseif digest > 0.5  then return { holo = Y }
        else return { foil = Y } end
        return 
    end
    if     digest > 1 - 0.003*_mod and not _no_neg then return { negative = Y }
    elseif digest > 1 - 0.006*rate*_mod            then return { polychrome = Y }
    elseif digest > 1 - 0.02*rate*_mod             then return { holo = Y }
    elseif digest > 1 - 0.04*rate*_mod             then return { foil = true } end
end

return M
