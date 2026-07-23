local push = table.insert
local M = {}

-- Require once, dot-notation
local mods = {
	format_utils       = require("HMfns.utils.format.math_format"),
	i18n_utils         = require("HMfns.utils.format.i18n_utils"),
	math_utils         = require("HMfns.utils.math.math_utils"),
	motion_utils       = require("HMfns.utils.math.motion_utils"),
	
    rng_utils          = require("HMfns.utils.math.rng_utils"),
	sound_utils        = require("HMfns.utils.sound_utils"),
	table_utils        = require("HMfns.utils.table_utils"),	
}

-- Helpers --------------------------------------------------------------------
local function ensure_ns(root, dotted)
	local t = root
	for seg in dotted:gmatch("[^%.]+") do t[seg] = t[seg] or {}; t = t[seg] end
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

-- spec rows: {to="name.or.namespace", mod="key in mods", fn="moduleFnName", kind="gm"|"pure"|nil}
local exports = {
	-- Table (pure)
	{ to="contains",                 mod="table_utils",   fn="contains",                  kind="pure"},
    { to="wipe",                     mod="table_utils",   fn="wipe",                      kind="pure" },
	{ to="destroy_tree",             mod="table_utils",   fn="destroy_tree",              kind="pure" },
	{ to="index_of",                 mod="table_utils",   fn="index_of",                  kind="pure" },
	{ to="densify",                  mod="table_utils",   fn="densify",                   kind="pure" },
	{ to="swap_at",                  mod="table_utils",   fn="swap_at",                   kind="pure" },
	{ to="sort_then_shuffle",        mod="table_utils",   fn="sort_then_shuffle",         kind="pure" },
	{ to="deep_copy",                mod="table_utils",   fn="deep_copy",                 kind="pure" },
    { to="random_pick",              mod="table_utils",   fn="random_pick",               kind="pure" },

	-- -- Math (pure)
	{ to="lerp",                     mod="math_utils",    fn="lerp",                      kind="pure" },
	{ to="xf_dist",                  mod="math_utils",    fn="xf_dist",                   kind="pure" },
	{ to="vec_len",                  mod="math_utils",    fn="vec_len",                   kind="pure" },
	{ to="vec_sub",                  mod="math_utils",    fn="vec_sub",                   kind="pure" },
	{ to="vec_translate_inplace",    mod="math_utils",    fn="vec_translate_inplace",     kind="pure" },
	{ to="vec_rotate_inplace",       mod="math_utils",    fn="vec_rotate_inplace",        kind="pure" },
	{ to="smooth_damp",              mod="motion_utils",  fn="smooth_damp",               kind="pure" },

	-- RNG
    { to="hash_unit32",              mod="rng_utils",     fn="hash_unit32",               kind="gm" },
    { to="hash_string32",            mod="rng_utils",     fn="hash_string32",             kind="pure" },
    { to="seeded_random",            mod="rng_utils",     fn="seeded_random",             kind="gm" },
    { to="weighted_refs",            mod="rng_utils",     fn="weighted_refs",             kind="pure" },
    { to="weighted_pick",            mod="rng_utils",     fn="weighted_pick",             kind="gm" },
    { to="rand_str",                 mod="rng_utils",     fn="rand_str",                  kind="pure" }, 
    { to="fetch_starting_seed",      mod="rng_utils",     fn="fetch_starting_seed",       kind="gm" },

	-- Sound
	{ to="play_clip",                mod="sound_utils",   fn="play_clip",                 kind="gm"   },
    { to="reset_snd_states",         mod="sound_utils",   fn="reset_snd_states",          kind="pure" },

	-- Formatting
	{ to="format_num",               mod="format_utils",  fn="format_num",                kind="pure"   },
	{ to="scale4score",              mod="format_utils",  fn="scale4score",               kind="pure"   },
    { to="timestamp",                mod="format_utils",  fn="make_timestamp",            kind="pure"   },

	-- I18N
	{ to="i18n",                     mod="i18n_utils",    fn="i18n",                      kind="gm" },
    { to="init_i18n_dict",           mod="i18n_utils",    fn="init_i18n_dict",            kind="gm" }
}

function M.register(gm)
	gm.Fs = gm.Fs or {}
	for _, e in ipairs(exports) do
		local source = ("systems.%s.%s"):format(e.mod, e.fn)
		local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
		local fn     = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
		local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
		set_func(gm.Fs, e.to, out_fn, source)


	end
end

return M
