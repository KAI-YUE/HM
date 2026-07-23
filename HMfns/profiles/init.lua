local push = table.insert
local M = {}

-- one-shot requires (dot notation)
local mods = {
    -- Gallery related
    achm             = require("HMfns.profiles.gallery.achievements"),
    career           = require("HMfns.profiles.gallery.career"),
    deck_win         = require("HMfns.profiles.gallery.deck_win"),
    joker_win        = require("HMfns.profiles.gallery.joker_win"),

    profile_actions  = require("HMfns.profiles.profile_actions"),
    progress_utils   = require("HMfns.profiles.progress_utils"),

    profile_snapshot = require("HMfns.profiles.profile_snapshot")
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
    -- Achievements 
    { to="init_achievements",       mod="achm",             fn="init_achievements",      kind="gm" },
    { to="grant_achievements",      mod="achm",             fn="grant_achievements",     kind="gm" },
    
    -- Career
    { to="update_career",           mod="career",           fn="update_career",          kind="gm" },
    
    -- Deck win
    { to="inc_deck_usage",          mod="deck_win",         fn="inc_deck_usage",         kind="gm" },
    { to="inc_deck_win",            mod="deck_win",         fn="inc_deck_win",           kind="gm" },
    { to="inc_deck_loss",           mod="deck_win",         fn="inc_deck_loss",          kind="gm" },
    { to="fetch_deck_win_sticker",  mod="deck_win",         fn="fetch_deck_win_sticker", kind="gm" },
    { to="deck_max_win_stake",      mod="deck_win",         fn="deck_max_win_stake",     kind="gm" }, 
    -- Joker win 
    { to="retrieve_joker",          mod="joker_win",       fn="retrieve_joker",          kind="gm" },
    { to="inc_joker_usage",         mod="joker_win",       fn="inc_joker_usage",         kind="gm" },
    { to="inc_joker_win",           mod="joker_win",       fn="inc_joker_win",           kind="gm" },
    { to="fetch_joker_win_sticker", mod="joker_win",       fn="fetch_joker_win_sticker", kind="gm" },

    -- Profile related actions
    { to="load_profile",            mod="profile_actions",  fn="load_profile",           kind="gm" },
    { to="delete_profile",          mod="profile_actions",  fn="delete_profile",         kind="gm" },
    { to="unlock_all",              mod="profile_actions",  fn="unlock_all",             kind="gm" }, 

	-- Profile progress & discovery
	{ to="set_progress",            mod="progress_utils",   fn="set_progress",           kind="gm" },
	{ to="set_discoveries",         mod="progress_utils",   fn="set_discoveries",        kind="gm" },
    { to="log_consumable_usage",    mod="progress_utils",   fn="log_consumable_usage",   kind="gm" },
    { to="log_voucher_usage",       mod="progress_utils",   fn="log_voucher_usage",      kind="gm" },

    -- profile_snapshot
    { to="build_state_dict",        mod="profile_snapshot",         fn="build_state_dict",       kind="gm" },
    { to="save_state_dict",         mod="profile_snapshot",         fn="save_state_dict",        kind="gm" },
    { to="delete_state_dict",       mod="profile_snapshot",         fn="delete_state_dict",      kind="gm" },
    { to="convert_save_to_meta",    mod="profile_snapshot",         fn="convert_save_to_meta",   kind="gm" },
}

function M.register(gm)
	gm.Fs = gm.Fs or {}
	for _, e in ipairs(exports) do
		local source = ("profiles.%s.%s"):format(e.mod, e.fn)
		local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
		local fn     = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
		local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
		set_func(gm.Fs, e.to, out_fn, source)
	end
end

return M
