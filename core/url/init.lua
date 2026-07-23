local push = table.insert
local M = {}

-- one-shot requires (dot notation)
local mods = {
    URL = require("core.url.open_url")
}

-- Helpers --------------------------------------------------------------------
local function ensure_ns(root, dotted)
	local t = root
	for seg in dotted:gmatch("[^%.]+") do t[seg] = t[seg] or {};  t = t[seg] end
	return t
end

local function set_func(root, dotted, fn, source)
	local parts = {}
	for seg in dotted:gmatch("[^%.]+") do parts[#parts+1] = seg end
	local last = parts[#parts]
	local tbl = (#parts > 1) and ensure_ns(root, table.concat(parts, ".", 1, #parts-1)) or root
	assert(type(tbl[last]) ~= "function", ("Duplicate gm.Fs key: %s (from %s)"):format(dotted, source))
	assert(type(tbl[last]) ~= "table", ("Name conflict (table exists) for %s (from %s)"):format(dotted, source))
	tbl[last] = fn
end

local function wrap_pure(fn)
return function(a, ...)
    if type(a) == "table" and (a.Fs or a.SET or a.Ver) then return fn(...)
    else return fn(a, ...) end  -- If first arg “looks like gm” (a table with Fs/SET/etc), drop it.
end
end


local exports = {
    { to="demo_survey",              mod="URL",               fn="demo_survey",               kind="pure" },
    { to="wishlist_steam",           mod="URL",               fn="wishlist_steam",            kind="pure" },
    { to="go_to_discord",            mod="URL",               fn="go_to_discord",             kind="pure" },
    { to="loc_survey",               mod="URL",               fn="loc_survey",                kind="pure" },
    { to="go_to_x",                  mod="URL",               fn="go_to_x",             kind="pure" }
}

function M.register(gm)
	gm.Fs = gm.Fs or {}
	for _, e in ipairs(exports) do
		local source = ("url.%s.%s"):format(e.mod, e.fn)
		local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
		local fn     = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
		local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
		set_func(gm.Fs, e.to, out_fn, source)
	end
end

return M
