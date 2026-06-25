local RNG = require("HMfns.utils.math.rng_utils")
local Factory = require("HMGplay.cards.factory")

local spawn_card  = Factory.spawn_card
local seeded_rand = RNG.seeded_random
local Y, N = true, false

local M = {}

--------------------------------------------------
--- spawn shop card
--------------------------------------------------
function M.spawn_shop_card(gm, zone)
    local card = nil;                                       local SET   = gm.SET
    local tp = SET.tutorial_progress;                       local fshop = tp and tp.forced_shop

    if zone == gm.shop_jokers and fshop and fshop[#fshop] then --- This is for tutorial demo shop
        local _center  = gm.CMod[fshop[#fshop]] or gm.CMod.c_empress
        local Card, aT = require("HMEng.entities.card"), zone.T
        card = Card(gm, aT.x + aT.w/2, aT.y, gm.card_w, gm.card_h, gm.P_CARDS.empty, _center, { bypass_discovery_center = Y, bypass_discovery_ui = Y})
        fshop[#fshop] = nil
        if not fshop[1] then tp.forced_shop = nil end
        create_shop_card_ui(card)
        return card
    end

    local gG, forced_tag = gm.GAME, nil;                    local gtags = gG.tags  
    for k, v in ipairs(gtags) do
        if forced_tag then return forced_tag end
        forced_tag = v:apply_to_run({ type = "store_joker_create", zone = zone })
        if forced_tag then for kk, vv in ipairs(gtags) do if vv:apply_to_run({ type = "store_joker_modify", card = forced_tag }) then break end end end
    end

    -- default rate                 20              4               0                 0                     0 
    local jr, tr, pr, pcr, sr = gG.joker_rate, gG.tarot_rate, gG.planet_rate, gG.playing_card_rate, gG.spectral_rate
    gG.spectral_rate  = gG.spectral_rate or 0;              local total_rate  = jr + tr + pr + pcr + sr
    local polled_rate = seeded_rand(gm, "cdt")*total_rate;  local check_rate, EB = 0, "Base"

    if gG.used_vouchers["v_illusion"] and seeded_rand(gm, "illusion") > 0.6 then EB = "Enhanced" end

    local valid_lists = { { type = "Joker", val = jr }, { type = "Tarot", val = tr }, { type = "Planet", val = pr }, { type = EB, val = pcr }, { type = "Spectral", val = sr } }
    local EM = gm.E_MANAGER

    for i, v in ipairs(valid_lists) do
        if polled_rate <= check_rate or polled_rate > check_rate + v.val then goto continue end  

        card = spawn_card(gm, v.type, zone, nil, nil, nil, nil, nil, "sho"..i)
        create_shop_card_ui(card, v.type, zone)
        EM:enqueue_event({ func = function() for k, v in ipairs(gtags) do if v:apply_to_run({ type = "store_joker_modify", card = card }) then break end end; return Y end })
        if (v.type == "Base" or v.type == "Enhanced") and gG.used_vouchers["v_illusion"] and seeded_rand(gm, "illusion") > 0.8 then 
            local edition_poll, edition = seeded_rand(gm, "illusion"), {}
            if     edition_poll > 0.85 then edition.polychrome = Y
            elseif edition_poll > 0.5 then edition.holo = Y
            else   edition.foil = Y end
            card:set_edition(edition)
        end
        if card then return card end
        ::continue::
        check_rate = check_rate + v.val
    end
    return card
end

--------------------------------------------------
--- Inc shop size
--------------------------------------------------
function M.inc_shop_size(gm, mod)
    local gG = gm.GAME;                local gshop = gG.shop
	if not gshop then return end
	gshop.joker_max = gshop.joker_max + mod

    local gsj = gm.shop_jokers
	if not gsj or not gsj.cards then return end 
    if mod < 0 then for i = #gsj.cards, gshop.joker_max + 1, -1 do if gsj.cards[i] then gsj.cards[i]:remove() end end; return end
    
    gsj.config.card_limit = gshop.joker_max
    gsj.T.w = gshop.joker_max * 1.01 * gm.card_w
    gm.shop:recalculate()

    for i = 1, gshop.joker_max - #gsj.cards do gsj:emplace(M.spawn_shop_card(gm, gm.shop_jokers)) end
end

return M