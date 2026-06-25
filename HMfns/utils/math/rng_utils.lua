local rand = math.random

local Y, N = true, false

local rng_utils = {}

---------------------------------------------------------------------------------------
--- Deterministic, non-cryptographic string -> [0,1) float. Set `use_fmix=true` for extra diffusion.
---------------------------------------------------------------------------------------
-- 32-bit Helpers that work with LuaJIT"s `bit`, Lua 5.2"s `bit32`, or pure Lua fallback.
local bxor, rshift
local function mul32(a, b) return (a * b) % 0x100000000 end

if bit       then bxor, rshift = bit.bxor, bit.rshift
elseif bit32 then bxor, rshift = bit32.bxor, bit32.rshift end

-- FNV-1a (Fowler–Noll–Vo) 32-bit constants
local FNV_OFFSET, FNV_PRIME = 0x811c9dc5, 0x01000193

-- Murmur3 fmix32 finalizer for better avalanche
local function fmix32(h)
	h = bxor(h, rshift(h, 16)); h = mul32(h, 0x85ebca6b)
	h = bxor(h, rshift(h, 13)); h = mul32(h, 0xc2b2ae35)
	h = bxor(h, rshift(h, 16))
	return h
end

-- Deterministic, non-crypto 32-bit hash of a string
function rng_utils.string32(str, use_fmix)
	str = tostring(str or "")
	local h = FNV_OFFSET
	for i = 1, #str do h = bxor(h, str:byte(i)); h = mul32(h, FNV_PRIME) end
	if use_fmix then h = fmix32(h) end
	return h % 0x100000000
end

--__________________________________
--- Main: string to float 
--__________________________________
function rng_utils.hash_string32(str)
    local use_fmix = Y
	local h = rng_utils.string32(str, use_fmix)
	return h / 4294967296.0 -- divide by 2^32 to get [0,1)
end

---------------------------------------------------------------------------------------
--- hash unit: given a stable pseudohash(key), 32-bit int, returns a float in [0,1)
---------------------------------------------------------------------------------------
function rng_utils.hash_unit32(gm, key, salt)
	if key == "seed" then return rand() end
    local game, _hash  = gm.GAME, rng_utils.hash_string32
    local seed, u, key = game.pseudorandom.seed or "", 0, tostring(key or "")
    if salt then return _hash(key..tostring(salt).. seed, true) end

	game.pseudorandom       = game.pseudorandom or {};              local pr = game.pseudorandom
    pr.seed, pr.hashed_seed = pr.seed or "", pr.hashed_seed or 0

    u = _hash(key..pr.seed, true)
	if not pr[key] then pr[key] = u end
    pr[key] = _hash(string.format("%.8f", (math.pi + pr[key]*1.5)%1)) -- Update the pseudo random key 
    return 0.5*(pr[key] + (pr.hashed_seed or 0))
end

----------------------------------------------------------------------
--- Seeded random 
----------------------------------------------------------------------
function rng_utils.seeded_random(gm, seed, min, max)
	if type(seed) == "string" then seed = rng_utils.hash_unit32(gm, seed) end
	math.randomseed(seed)
	if min and max then return rand(min, max) end
	return rand()
end

---------------------------------------------
--- weighted refs
---------------------------------------------
function rng_utils.weighted_refs(weights)
	local refs = {}
	for ref, weight in pairs(weights or {}) do if weight and weight > 0 then refs[#refs + 1] = ref end end
	table.sort(refs, function(a, b)
		local ta, tb = type(a), type(b)
		if ta ~= tb then return ta < tb end
		return tostring(a) < tostring(b)
	end)
	return refs
end

---------------------------------------------
--- weighted pick
---------------------------------------------
function rng_utils.weighted_pick(gm, weights, seed)
	if not weights then return end

	local refs, total = rng_utils.weighted_refs(weights), 0
	for _, ref in ipairs(refs) do total = total + (weights[ref] or 0) end
	if total <= 0 then return end

	local roll_unit
	roll_unit = rng_utils.hash_unit32(gm, seed or "weighted_pick", "weighted_pick")

	local roll, acc = roll_unit*total, 0
	for _, ref in ipairs(refs) do acc = acc + (weights[ref] or 0); if roll <= acc then return ref end end
	return refs[#refs]
end

-------------------------------------------------
--- random string 
-------------------------------------------------
function rng_utils.rand_str(length, seed)
	if seed then math.randomseed(seed) end
	local ret = ""
	for i = 1, length do ret = ret .. string.char( rand() > 0.7 and rand(string.byte("1"), string.byte("9")) or rand(string.byte("A"), string.byte("Z")) ) end
	return string.upper(ret)
end

-------------------------------------------------
--- start seed 
------------------------------------------------
function rng_utils.fetch_starting_seed(gm)
	local _ch = gm.CTRL.cursor_hover
    return rng_utils.rand_str(4, _ch.T.x * 0.3 + _ch.T.y * 0.8 + 0.4 * _ch.time)
end

return rng_utils
