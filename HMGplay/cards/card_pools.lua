local TabUtils   = require("HMfns.utils.table_utils")
local RNG        = require("HMfns.utils.math.rng_utils")

local shuffle     = TabUtils.shuffle_in_place
local wipe,  rand = TabUtils.wipe,   math.random
local seeded_rand = RNG.seeded_random
local _hash, push = RNG.hash_unit32, table.insert

local Y, N        = true, false

local M = {}

-------------------------------------------
--- Register card discovery
-------------------------------------------
function M.register_card_discovery(gm, card)
    local gG, F, EM = gm.GAME, gm.Fs, gm.E_MANAGER
	if gG.seeded or gG.challenge then return end
    
    card = card or {}
    local rscores = gG.round_scores
	if card.discovered or card.wip then return end
	if not card.discovered then card.alert, rscores.new_collection.amt = Y, rscores.new_collection.amt + 1 end
	
    card.discovered = true
	F.set_discoveries(gm)
    gm:save_progress()
end

----------------------------------------------------------------
--- Fetch current pool 
----------------------------------------------------------------

--___________________________________
--- Main: fetch_current_pool
--___________________________________
function M.fetch_current_pool(gm)
end

return M