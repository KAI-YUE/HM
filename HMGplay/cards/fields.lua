local TabUtils   = require("HMfns.utils.table_utils")
local RNG        = require("HMfns.utils.math.rng_utils")
local Factory    = require("HMGplay.cards.factory")

local seeded_rand, _hash = RNG.seeded_random,  RNG.hash_unit32
local contains, _pick    = TabUtils.contains,  TabUtils.random_pick
local deep_copy, push    = TabUtils.deep_copy, table.insert

local Y, N  = true, false

local M = {}

-------------------------------------------------------------------
--- spawn card2deck
-------------------------------------------------------------------
--- Helper: build spawn card data
local function _build_spawn_card(args)
    local card = args.card and deep_copy(args.card) or { suit = args.s, rank = args.r, name = args.r.."of"..args.s }
    card.suit = card.suit or args.s
    card.rank = card.rank or args.r
    card.name = card.name or (tostring(card.rank).."of"..tostring(card.suit))
    return card
end

---____________________
--- main: spawn card2deck 
---____________________
function M.spawn_card2deck(gm, args)
    local Card, deck = require("HMEng.entities.card"), gm.deck     
    local _card, dT  = _build_spawn_card(args), deck.T
    
    local _card = Card(gm, dT.x, dT.y, gm.card_w, gm.card_h, _card, gm.CMod[args.e or "c_base"], args)
    if args.d then _card:set_edition({ [ args.d ] = Y }, Y, Y) end
    if args.g then _card:set_seal(args.g, Y, Y) end
    deck:emplace(_card)
end

------------------------------------
--- spawn special card2deck 
------------------------------------
function M.spawn_special_card2deck(gm, card_set, card_key, args)
    local args = args or {}
    local def = Factory.fetch_special_card_def(card_set, card_key)
    if not def then return end

    local card = Factory.spawn_special_card(def, card_key, args)
    M.spawn_card2deck(gm, { card = card, e = args.e, d = args.d, g = args.g, facing = args.facing })
    return card
end

-------------------------------------------------------------------
--- spawn card2field
-------------------------------------------------------------------
function M.spawn_card2field(gm, args)
    local Card,  field  = require("HMEng.entities.card"), gm.field     
    local _card, fT     = _build_spawn_card(args), field.T
    
    -- local _card = Card(gm, fT.x, fT.y, gm.card_w, gm.card_h, _card, gm.CMod[args.e or "c_base"], { template_shader = "twisted", facing = args.facing })
    local _card = Card(gm, fT.x, fT.y, gm.card_w, gm.card_h, _card, gm.CMod[args.e or "c_base"], { template_shader = "generic", facing = args.facing })
    if args.d then _card:set_edition({ [ args.d ] = Y }, Y, Y) end
    if args.g then _card:set_seal(args.g, Y, Y) end
   
    field:emplace_card(_card, args.r_idx, args.c_idx)
end

------------------------------------
--- spawn special card2field
------------------------------------
function M.spawn_special_card2field(gm, card_set, card_key, args)
    local args = args or {}
    local def  = Factory.fetch_special_card_def(card_set, card_key)
    if not def then return end

    local card = Factory.spawn_special_card(def, card_key, args)
    M.spawn_card2field(gm, { card = card, e = args.e, d = args.d, g = args.g, r_idx = args.r_idx, c_idx = args.c_idx, facing = args.facing or "front" })
    return card
end

return M 
