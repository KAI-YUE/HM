local push = table.insert
local M = {}

-- one-shot requires (dot notation)
local mods = {
    -- Card 
    card_pool     = require("HMGplay.cards.card_pools"),
    card_factory  = require("HMGplay.cards.factory"),
    card_fields   = require("HMGplay.cards.fields"),

    -- Draw deal 
    draw_deal     = require("HMGplay.cards.draw_deal"),

    -- Economy
    economy        = require("HMGplay.economy"), 

    -- Rule 
	hand_actions   = require("HMGplay.rules.hand_actions"),
    hand_eva       = require("HMGplay.rules.hand_eva"),
    rule_start     = require("HMGplay.rules.start"),

    -- Shop 
    shop_stock     = require("HMGplay.shop.stock"),

    -- Scoring 
    scoring        = require("HMGplay.scoring"),

    -- Run Flow
    run_flow       = require("HMGplay.run_flow"),
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
    -- Card: Pool
    { to="fetch_current_pool",       mod="card_pool",        fn="fetch_current_pool",      kind="gm" },
    { to="register_card_discovery",  mod="card_pool",        fn="register_card_discovery", kind = "gm" },
    -- Card: Factory
    { to="spawn_card",               mod="card_factory",     fn="spawn_card",              kind="gm" },
    { to="spawn_playing_cards",      mod="card_factory",     fn="spawn_playing_cards",     kind="gm" },
    { to="clone_card",               mod="card_factory",     fn="clone_card",              kind="gm" },
    { to="roll_edition",             mod="card_factory",     fn="roll_edition",            kind="gm" },
    -- Card: Fields
    { to="spawn_card2deck",          mod="card_fields",      fn="spawn_card2deck",         kind="gm" },
    { to="spawn_special_card2deck",  mod="card_fields",      fn="spawn_special_card2deck", kind="gm" },
    { to="spawn_card2field",         mod="card_fields",      fn="spawn_card2field",        kind="gm" },
    { to="spawn_special_card2field", mod="card_fields",      fn="spawn_special_card2field",kind="gm" },

    -- Draw & Deal 
    { to="draw_from_to",             mod="draw_deal",        fn="draw_from_to",            kind="gm" },
    { to="draw_deck2hand",           mod="draw_deal",        fn="draw_deck2hand",          kind="gm" },
    { to="draw_play2discard",        mod="draw_deal",        fn="draw_play2discard",       kind="gm" },
    { to="draw_play2hand",           mod="draw_deal",        fn="draw_play2discard",       kind="gm" },
    { to="draw_discard2deck",        mod="draw_deal",        fn="draw_discard2deck",       kind="gm" },
    { to="draw_hand2deck",           mod="draw_deal",        fn="draw_hand2deck",          kind="gm" },
    { to="draw_hand2discard",        mod="draw_deal",        fn="draw_hand2discard",       kind="gm" },

    -- Economy 
    { to="add_money",                mod="economy",          fn="add_money",               kind="gm" },

	-- Hand Actions
	{ to="sort_hand_suit",           mod="hand_actions", 	fn="sort_hand_suit",          kind="gm" },
    { to="sort_hand_value",          mod="hand_actions",     fn="sort_hand_value",         kind="gm" },
    -- Hand evaluate
    { to="evaluate_hand",            mod="hand_eva",         fn="evaluate_hand",           kind="gm" },
    { to="fetch_flush",              mod="hand_eva",         fn="fetch_flush",             kind="gm" },
    { to="fetch_straight",           mod="hand_eva",         fn="fetch_straight",          kind="gm" },
    { to="fetch_highest",            mod="hand_eva",         fn="fetch_highest",           kind="gm" },
    { to="fetch_N_of_Akind",         mod="hand_eva",         fn="fetch_N_of_Akind",        kind="gm" },
    { to="poker_hand_info",          mod="hand_eva",         fn="poker_hand_info",         kind="gm" },

    -- Rules
    { to="init_gameplay_params",     mod="rule_start",       fn="init_gameplay_params",    kind="pure" },
    { to="init_deck",                mod="rule_start",       fn="init_deck",               kind="gm" }, 
    { to="init_field",               mod="rule_start",       fn="init_field",              kind="gm" },
    { to="init_field_progressive",   mod="rule_start",       fn="init_field_progressive",  kind="gm" },

    -- Shop
    { to="spawn_shop_card",          mod="shop_stock",       fn="spawn_shop_card",         kind="gm" },
    { to="inc_shop_size",            mod="shop_stock",       fn="inc_shop_size",           kind="gm" },

    -- Scoring 
    { to="update_high_score",        mod="scoring",          fn="update_high_score",       kind="gm" },
}

function M.register(gm)
	gm.Fs = gm.Fs or {}
	for _, e in ipairs(exports) do
		local source = ("gameplay.%s.%s"):format(e.mod, e.fn)
		local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
		local fn     = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
		local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
		set_func(gm.Fs, e.to, out_fn, source)
	end

    mods.run_flow.register(gm)
end

return M
