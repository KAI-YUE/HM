local Actor     = require("HMEng.actors.actor")
local CPOOLS   = require("HMGplay.cards.card_pools")
local I18N     = require("HMfns.utils.format.i18n_utils")
local TabUtils = require("HMfns.utils.table_utils")

local i18n     = I18N.i18n
local contains = TabUtils.contains
local register_card_discovery = CPOOLS.register_card_discovery
local min, max = math.min, math.max

local sCode  = { diamond = "D_", spade = "S_", club = "C_", heart = "H_" }
local _b     = { "Ace", "King", "Queen", "Jack", "10"  }
local bValue = { Ace = "A", King = "K", Queen = "Q", Jack = "J", ["10"] = "T" }
local Y, N   = true, false

return function (Card)
-----------------------------------------
--- Collides with
-----------------------------------------
function Card:hit_test(point) return Actor.hit_test(self, point) end

-----------------------------------------
--- Change suit 
-----------------------------------------
function Card:change_suit(new_suit)

end

-----------------------------------------
--- Add 2 deck 
-----------------------------------------
--- Helper: ad-hoc add and ability 
function Card:_adhoc_add_and_ab()
    local ab, gm    = self.ability, self.gm;        local aname, gG, F = ab.name, gm.GAME, gm.Fs
    local Gb, extra = gG.blind, ab.extra;           local cr, rr, EM = gG.current_round, gG.round_resets, gm.E_MANAGER
    local ghand, ed = gm.hand, self.edition
    
    if not ed or not ed.negative then return end
    if from_debuff then ab.queue_negative_removal = nil; return end
    local _cons, _j = gm.consumables, gm.jokers
    if ab.consumable then _cons.config.card_limit = _cons.config.card_limit + 1; return end
    _j.config.card_limit = _j.config.card_limit + 1
end

--____________________________________
--- Main 
--____________________________________
function Card:add_to_deck(from_debuff)
    local cfg, gm     = self.config, self.gm
    local F, center   = gm.Fs, cfg.template
    local _PC, ed, gG = gm.CMod, self.edition, gm.GAME

    if not center.discovered then F.register_card_discovery(gm, center) end
    if self.added_to_deck then return end;      self.added_to_deck = Y
    local ab = self.ability;                    local set, aname   = ab.set, ab.name

    if set == "Enhanced" or set == "Default" then return self:_handle_gold_card() end

    if ed then if not _PC["e_"..(ed.type)].discovered then register_card_discovery(gm, _PC["e_"..(self.edition.type)]) end
    else       if not _PC["e_base"].discovered then register_card_discovery(gm, _PC["e_base"]) end end
    
    if ab.h_size ~= 0 then gm.hand:change_size(ab.h_size) end
    if ab.d_size > 0  then gG.round_resets.discards = gG.round_resets.discards + ab.d_size; F.HUD_add_discard(gm, ab.d_size) end
    self:_adhoc_add_and_ab()
    if gG.blind then gm.E_MANAGER:enqueue_event({ func = function() gG.blind:set_blind(nil, Y, nil); return Y end }) end
end

-----------------------------------------------
--- Remove from deck 
-----------------------------------------------
--- Helper: ad-hoc remove 
function Card:_ad_hoc_remove()
    local gm, ab = self.gm, self.ability;              local gG, EM, ghand, F = gm.GAME, gm.E_MANAGER, gm.hand, gm.Fs
    local rr, cr = gG.round_resets, gG.current_round;  local aname, extra  = ab.name, ab.extra

    if ab.h_size ~= 0 then ghand:change_size(-ab.h_size) end
    if ab.d_size > 0  then rr.discards = rr.discards - ab.d_size; F.HUD_add_discard(gm, -ab.d_size) end
end

---___________________________
--- Main: remove from deck
---____________________________
function Card:remove_from_deck(from_debuff)
    if not self.added_to_deck then return end;      self.added_to_deck = N
    self:_ad_hoc_remove()

    local gm, ed = self.gm, self.edition;            local gG, EM = gm.GAME, gm.E_MANAGER
    local Gb, _j = gG.blind, gm.jokers

    local function _blind() if Gb then EM:enqueue_event({ func = function() Gb:set_blind(nil, Y, nil); return Y end }) end end
    if not ed or not ed.negative or not _j then return  _blind() end -- handle negative edition 

    local ab = self.ability
    if from_debuff then ab.queue_negative_removal = Y; return _blind() end 
    if ab.consumable then gm.consumables.config.card_limit = gm.consumables.config.card_limit - 1; return _blind() end 
    gm.jokers.config.card_limit = gm.jokers.config.card_limit - 1
    return _blind()
end


end
