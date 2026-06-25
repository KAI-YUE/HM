local Card     = require("HMEng.entities.card")
local SndUtils = require("HMfns.utils.sound_utils")
local TabUtils = require("HMfns.utils.table_utils")
local I18N, TC = require("HMfns.utils.format.i18n_utils"), require("HMfns.animate.transitions.tween_color")
local RNG, C   = require("HMfns.utils.math.rng_utils"), require("HMfns.animate.color.color_const")
local Factory  = require("HMGplay.cards.factory")

local spawn_card  = Factory.spawn_card
local i18n, _pick = I18N.i18n, TabUtils.random_pick
local play_clip   = SndUtils.play_clip
local _hash = RNG.hash_unit32
local rand, tween_color = math.random, TC.tween_color_to

local crd, cb   = C.RED, C.BLUE
local Y, N, _ta = true, false, "trigger"

return function (Deck)
------------------------------------------------
--- Trigger effect 
------------------------------------------------
--- Helper: plasma deck effect 
function Deck:_plasma_deck(args)
    local gm, c_snd, _cp     = self.gm, "gong", { 0.8, 0.45, 0.85, 1 }
    local F, _ch, _mult, C   = gm.Fs, args.chips, args.mult, gm.C
    local half_tot, text, _o = math.floor(0.5*(_ch + _mult)), i18n(gm, "k_balanced"), { x = 0,y = -2.7 }
    local EM = gm.E_MANAGER

    args.chips, args.mult = half_tot, half_tot
    F.HUD_update_hand_label(gm, { delay = 0 }, { mult = args.mult, chips = args.chips })

    local function _plasma()
        play_clip(gm, c_snd, 0.94, 0.3);        play_clip(gm, c_snd, 0.94*1.5, 0.2);  play_clip(gm, "tarot1", 1.5)
        tween_color(gm, C.UI_CHIPS, _cp);       tween_color(gm, C.UI_MULT, _cp)

        F.toast_attention(gm, { scale = 1.4, text = text, hold = 2, align = "cm", offset = _o, major = gm.play })
        EM:enqueue_event({ trigger = _ta, blockable = N, blocking = N, delay = 4.3, func = (function() tween_color(C.UI_CHIPS, cb, 2); tween_color(C.UI_MULT, crd, 2) return Y end) })
        EM:enqueue_event({ trigger = _ta, blockable = N, blocking = N, no_delete = Y, delay = 6.3, func = (function() C.UI_CHIPS = F.deep_copy(cb); C.UI_MULT = F.deep_copy(crd); return Y end) })
        return Y
    end
    EM:enqueue_event({ func = function() return _plasma() end })
    F.sleep(gm, 0.6)
    return args.chips, args.mult
end

--___________________________________
--- Main 
--___________________________________
function Deck:trigger_effect(args)
    if not args then return end
    local gm, name, _ctx = self.gm, self.name, args.context
    local gG = gm.GAME;          local gGb =  gG.last_blind
end
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

---------------------------------------------
-- Apply to run 
---------------------------------------------
--- Helper: voucher
local function _voucher(gG, _PC, voucher, ctx)
    gG.used_vouchers[voucher] = Y
    gG.starting_voucher_count = (gG.starting_voucher_count or 0) + 1
    Card.apply_to_run(nil, _PC[voucher], ctx)
end

--- Helper: edition 
local function _edition(gm, ed, cfg)
    local function _set_edition()
        local i = 0
        while i < cfg.edition_count do
            local card = _pick(gm.run_card_id)
            if not card.edition then i = i + 1; card:set_edition({[ed] = Y}, nil, Y) end
        end;   return Y
    end
    gm.E_MANAGER:enqueue_event({ func = function() return _set_edition() end })
end

--- Helper: checkered deck
local function _cdeck(gm)
    for k, v in pairs(gm.run_card_id) do
        local vbs = v.base.suit
        if vbs == "club"    then v:change_suit("spade") end
        if vbs == "diamond" then v:change_suit("heart") end
    end;   return Y
end
local function _checkered(gm) gm.E_MANAGER:enqueue_event({ func = function() return _cdeck(gm) end }) end

--___________________________________
--- Main
--___________________________________
function Deck:apply_to_run()
    local gm, cfg, name  = self.gm, self.effect.config, self.name
    local gG, F, EM, _PC = gm.GAME, gm.Fs, gm.E_MANAGER, gm.CMod
    local _sparams       = gG.starting_params 

    local voucher, hands, cons    = cfg.voucher,  cfg.hands,           cfg.consumables 
    local vouchers, jslot, cslot  = cfg.vouchers, cfg.joker_slot,      cfg.consumable_slot
    local dollars, rfaces, spr    = cfg.dollars,  cfg.remove_faces,    cfg.spectral_rate
    local discards, rdis, edition = cfg.discards, cfg.reroll_discount, cfg.edition

    if voucher  then _voucher(gG, _PC, voucher, { gm = gm }) end
    if hands    then _sparams.hands = _sparams.hands + hands end
    if dollars  then _sparams.dollars = _sparams.dollars + dollars end
    if rfaces   then _sparams.no_faces = Y end
    if spr      then gG.spectral_rate = spr end
    if discards then _sparams.discards = _sparams.discards + discards end
    if rdis     then _sparams.reroll_cost = _sparams.reroll_cost - rdis end
    if edition  then _edition() end
    if vouchers then for k, v in pairs(vouchers) do _voucher(gG, _PC, v, { gm = gm }) end end

    if name == "Checkered Deck" then _checkered(gm) end
    if cfg.randomize_rank_suit  then _sparams.erratic_suits_and_ranks = Y end
    if jslot                    then _sparams.joker_slots = _sparams.joker_slots + jslot end
    if cfg.hand_size            then _sparams.hand_size = _sparams.hand_size + cfg.hand_size end
    if cfg.ante_scaling         then _sparams.ante_scaling = cfg.ante_scaling end
    if c_slot                   then _sparams.consumable_slots = _sparams.consumable_slots + cfg.consumable_slot end
    if cfg.no_interest          then gG.modifiers.no_interest = Y end
    if cfg.extra_hand_bonus     then gG.modifiers.money_per_hand = cfg.extra_hand_bonus end
    if cfg.extra_discard_bonus  then gG.modifiers.money_per_discard = cfg.extra_discard_bonus end
end

end