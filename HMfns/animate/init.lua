local push = table.insert
local M = {}

-- one-shot requires (dot notation)
local mods = {
    -- Color 
    color_utils     = require("HMfns.animate.color.color_utils"),
    color_stake     = require("HMfns.animate.color.color_stake"),

    -- transitions 
    tween_color     = require("HMfns.animate.transitions.tween_color"),
    trans_wipe      = require("HMfns.animate.transitions.screen_wipe"),

    -- jitter canvas 
    canvas_jitter   = require("HMfns.animate.canvas.jitter_canvas"),

    -- start
    start_deck      = require("HMfns.animate.start.deck"),
    start_hand_fan  = require("HMfns.animate.start.hand_fan")
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

-- export spec: { to="Fs.name[.namespace]", mod="mods key", fn="module fn", kind="gm"|"pure" }
local exports = {
    --- canvas_jitter
    { to="jitter_canvas",            mod="canvas_jitter", fn="jitter_canvas",            kind="gm" },

    -- color_utils
    { to="hex_to_rgba",              mod="color_utils",   fn="hex_to_rgba",              kind="pure"},
    { to="lerp_colors",              mod="color_utils",   fn="lerp_colors",              kind="pure"}, 
    { to="tint",                     mod="color_utils",   fn="tint",                     kind="pure"},
    { to="shade",                    mod="color_utils",   fn="shade",                    kind="pure"},
    { to="set_alpha",                mod="color_utils",   fn="set_alpha",                kind="pure"},
    { to="fetch_stake_col",          mod="color_stake",   fn="fetch_stake_col",          kind="pure" },

    -- tween_color
    { to="tween_field_by",           mod="tween_color",   fn="tween_field_by",           kind="gm"},
	{ to="tween_color_to",           mod="tween_color",   fn="tween_color_to",           kind="gm" },
	{ to="tween_background_palette", mod="tween_color",   fn="tween_background_palette", kind="gm" },
    { to="tween_background_blind",   mod="tween_color",   fn="tween_background_blind",   kind="gm" },

    -- Transition 
    { to="start_wipe_fx",            mod="trans_wipe",    fn="start_wipe_fx",            kind="gm" },
    { to="finish_wipe_fx",           mod="trans_wipe",    fn="finish_wipe_fx",           kind="gm" },

    -- Start
    { to="start.deck_fade_in",       mod="start_deck",     fn="animate_deck_fade_in",    kind="gm" },
    { to="start.hand_fan_out",       mod="start_hand_fan", fn="animate_hand_fan_out",    kind="gm" },
}

function M.register(gm)
	gm.Fs = gm.Fs or {}
	for _, e in ipairs(exports) do
		local source = ("animate.%s.%s"):format(e.mod, e.fn)
		local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
		local fn     = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
		local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
		set_func(gm.Fs, e.to, out_fn, source)

        -- ---- for debug purpose
        -- gm.DREG = gm.DREG or require("debug.skip_func_registry")
        -- push(gm.DREG, e.to) 
	end
end

return M
