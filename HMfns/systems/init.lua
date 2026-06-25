local push = table.insert
local M = {}

-- one-shot requires (dot notation)
local mods = {
    display     = require("HMfns.systems.display"),
    video       = require("HMfns.systems.video_settings"),

    render       = require("HMfns.systems.render"),
    
    -- Timer 
    timer        = require("HMfns.systems.timer"),
    
    -- Unlock
    unlocks      = require("HMfns.systems.unlocks"), 
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

-- export spec: { to="Fs.name[.namespace]", mod="mods key", fn="module fn", kind="gm"|"pure" }
local exports = {
    -- Display
    { to="fetch_display_info",    mod="display",       fn="fetch_display_info",        kind="gm" },
    { to="apply_window_settings", mod="video",         fn="apply_window_settings",     kind="gm" },

    -- Render 
    { to="add_to_drawable",       mod="render",        fn="add_to_drawable",           kind="gm" },
    { to="push_draw_transform",   mod="render",        fn="push_actor_draw_transform", kind="pure" },
    { to="enqueue_drawable",      mod="render",        fn="enqueue_drawable",          kind="pure" },
    { to="wipe_drawable",         mod="render",        fn="wipe_drawable",             kind="gm" },
    { to="shadows_toggle",        mod="render",        fn="shadows_toggle",            kind="gm" },
    { to="init_screen_pos",       mod="render",        fn="init_screen_pos",           kind="gm" },

    -- Timer 
    { to="sleep",                 mod="timer",         fn="sleep",                    kind="gm" },
    { to="timer_cpt",             mod="timer",         fn="timer_cpt",                kind="gm" },
    { to="tick_gc",               mod="timer",         fn="tick_gc",                  kind="gm" },
    { to="tqdm_timer",            mod="timer",         fn="tqdm_timer",               kind="gm" },

    -- Unlock 
    { to="unlock",                 mod="unlocks",       fn="unlock",                   kind="gm" },
    { to="inc_challenge_unlock",   mod="unlocks",       fn="inc_challenge_unlock",     kind="gm" },
    { to="handle_unlock_request",  mod="unlocks",       fn="handle_unlock_request",    kind="gm" },
    { to="toast_unlock_ntf",       mod="unlocks",       fn="toast_unlock_notification",kind="gm" }
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
