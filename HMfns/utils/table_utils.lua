-- functions/misc_functions/table_utils.lua
local table_utils = {}

-------------------------------
--- Wipe: wipe out a table 
-------------------------------
function table_utils.wipe(t)
	if not t then return {} end
	for k in pairs(t) do t[k] = nil end
	return t
end

--------------------------------
--- Destroy tree: destroy a hierarchy 
--------------------------------
function table_utils.destroy_tree(t)
    for i = #t, 1, -1 do
        local v = t[i];            table.remove(t, i)
        if v and v.children then remove_all(v.children) end
        if v then v:remove() end;  v = nil
    end
    for _, v in pairs(t) do
        if v.children then remove_all(v.children) end
        v:remove();                 v = nil
    end
end

----------------------------------------------
--- Index of: find the index of a table element
----------------------------------------------
function table_utils.index_of(t, val) for i, v in pairs(t) do if v == val then return i end end; return end

----------------------------------------------
--- Densify: remove nils 
----------------------------------------------
function table_utils.densify(t) local out = {}; for _, v in pairs(t) do if v ~= nil then out[#out+1] = v end end; return out end

------------------------------------------------------
--- swap at: swap the elements in a table given the two indices 
------------------------------------------------------
function table_utils.swap_at(t, i, j)
	if not t or not i or not j then return end
	t[i], t[j] = t[j], t[i]
end

---------------------------------------------------------
--- contains: determines if the table contains certain element
--------------------------------------------------------
function table_utils.contains(t, x)
    if not t then return false end
	for i = 1, #t do if t[i] == x then return true end end
	return false
end

--------------------------------------------------------
---  Sort then shuffle: Shuffle a table 
--------------------------------------------------------
-- optional Helper
function table_utils.sort_by_sort_id(t)
	table.sort(t, function(a, b) return (a.sort_id or 0) < (b.sort_id or 0) end)
	return t
end

-- pure Fisher–Yates; in-place; deterministic if rng provided
function table_utils.shuffle_in_place(t, rng)
	if rng then math.randomseed(rng) end
	for i = #t, 2, -1 do local j = math.random(i); t[i], t[j] = t[j], t[i] end
	return t
end

-- convenience: sort then shuffle
function table_utils.sort_then_shuffle(t, rng) table_utils.sort_by_sort_id(t); return table_utils.shuffle_in_place(t, rng) end

-------------------------------------------------
--- Deep copy 
-------------------------------------------------
function table_utils.deep_copy(o, opts, seen)
	opts, seen = opts or {}, seen or {}
	if type(o) ~= "table" then return o end
	if seen[o] then return seen[o] end

	local out = {};         seen[o] = out
	for k, v in pairs(o) do  -- copy array & hash parts
		local ck = opts.copy_keys and table_utils.deep_copy(k, opts, seen) or k
		out[ck] = table_utils.deep_copy(v, opts, seen)
	end
	if opts.copy_meta then
		local mt = getmetatable(o)
		if mt then setmetatable(out, table_utils.deep_copy(mt, opts, seen)) end
	end
	return out
end

--------------------------------------------------
--- Random pick: generate a random draw
--------------------------------------------------
function table_utils.random_pick(t, rng)
	if rng then math.randomseed(rng) end 
	local keys = {}
	for k, v in pairs(t) do keys[#keys+1] = { k = k, v = v } end
	if keys[1] and keys[1].v and type(keys[1].v) == "table" and keys[1].v.sort_id then
		table.sort(keys, function(a, b) return a.v.sort_id < b.v.sort_id end)
	else
		table.sort(keys, function(a, b) return a.k < b.k end)
	end
	local key = keys[math.random(#keys)].k
	return t[key], key
end

return table_utils
