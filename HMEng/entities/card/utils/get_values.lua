local Factory = require("HMGplay.cards.factory")
local RNG  = require("HMfns.utils.math.rng_utils")
local I18N = require("HMfns.utils.format.i18n_utils")

local i18n = I18N.i18n
local seeded_random = RNG.seeded_random
local spawn_card = Factory.spawn_card
local Y, N = true, false

return function (Card)
------------------------------------------
--- Get nominal
------------------------------------------
function Card:get_nominal(mod)
    local mult, base = 1, self.base
    if mod == "suit" then mult = 1000 end
    if self.ability.effect == "Stone" then mult = -1000 end
    return base.nominal + base.suit_nominal*mult
end

------------------------------------------
--- Get id
------------------------------------------
function Card:get_id() if self.ability.effect == "Stone Card" and not self.vampired then return -math.random(100, 1000000) end; return self.base.id end

------------------------------------------
--- is face
------------------------------------------
function Card:is_face(from_boss)
    if self.debuff and not from_boss then return end
    local id, gm = self:get_id(), self.gm
    if id == 11 or id == 12 or id == 13 or next(gm.Fs.fetch_joker(gm, "Pareidolia")) then return Y end
end

------------------------------------------
--- get chip bonus
------------------------------------------
function Card:get_chip_bonus()
    if self.debuff then return 0 end
    local ab = self.ability;          local pbonus = ab.perma_bonus or 0 
    if ab.effect == "Stone Card" then return ab.bonus + pbonus end
    return self.base.nominal + ab.bonus + pbonus
end

------------------------------------------
--- get chip mult
------------------------------------------
function Card:get_chip_mult()
    if self.debuff then return 0 end
    local gm, ab = self.gm, self.ability;       local gG = gm.GAME
    if ab.set == "Joker" then return 0 end
    if ab.effect == "Lucky Card" then 
        if seeded_random(gm, "lucky_mult") < gG.probabilities.normal/5 then self.lucky_trigger = Y; return ab.mult
        else return 0 end
    end
    return ab.mult
end

------------------------------------------
--- get chip x mult
------------------------------------------
function Card:get_chip_x_mult(context)
    if self.debuff then return 0 end
    local ab = self.ability
    if ab.set == "Joker" then return 0 end
    if ab.x_mult <= 1 then return 0 end
    return ab.x_mult
end

-----------------------------------------
--- Get chip h mult
-----------------------------------------
function Card:get_chip_h_mult() if self.debuff then return 0 end; return self.ability.h_mult end

-----------------------------------------
--- Get chip h x mult
-----------------------------------------
function Card:get_chip_h_x_mult() if self.debuff then return 0 end; return self.ability.h_x_mult end

-----------------------------------------
--- Get edition
-----------------------------------------
function Card:get_edition()
    if self.debuff then return end
    if not self.edition then return end 
    
    local ret, ed = { card = self }, self.edition
    if ed.x_mult then ret.x_mult_mod = ed.x_mult end
    if ed.mult   then  ret.mult_mod = ed.mult  end
    if ed.chips  then  ret.chip_mod = ed.chips end
    return ret
end

-----------------------------------------
--- Get end of round effect
-----------------------------------------
--- Helper: spawn planet card
local function _spawn_planet(gm, gG)
    if not gG.last_hand_played then return Y end 
    local _planet, card_type = 0, "Planet"
    for k, v in pairs(gm.P_CPools.Planet) do if v.config.hand_type == gG.last_hand_played then _planet = v.key end end
    local card = spawn_card(gm, card_type, gm.consumables, nil, nil, nil, nil, _planet, "blusl")
    card:add_to_deck()
    gm.consumables:emplace(card)
    gG.consumable_buffer = 0
    return Y
end

--- Main 
function Card:get_end_of_round_effect(context)
    if self.debuff then return {} end
    local ret, ab, gm = {}, self.ability, self.gm
    if ab.h_dollars > 0 then ret.h_dollars, ret.card = ab.h_dollars, self end

    local cons, gG = gm.consumables, gm.GAME
    if self.seal ~= "Blue" or #cons.cards + gG.consumable_buffer >= cons.config.card_limit then return ret end 
   
    gG.consumable_buffer = gG.consumable_buffer + 1
    gm.E_MANAGER:enqueue_event({ trigger = "before", func = function() return _spawn_planet(gm, gG) end })
    gm.Fs.show_card_status_text(gm, self, "extra", nil, nil, nil, { message = i18n(gm, "k_plus_planet"), color = gm.C.SECONDARY_SET.Planet })
    ret.effect = Y
    return ret
end

---------------------------------------
--- Get p dollars 
---------------------------------------
function Card:get_p_dollars()
    if self.debuff then return 0 end
    local ret = 0
    if self.seal == "Gold" then ret = ret +  3 end

    local gm, ab = self.gm, self.ability;       local gG = gm.GAME
    if ab.p_dollars > 0 then
        if ab.effect == "Lucky Card" then if seeded_random(gm, "lucky_money") < gG.probabilities.normal/15 then self.lucky_trigger, ret = Y, ret + ab.p_dollars end
        else  ret = ret + ab.p_dollars end
    end
    if ret <= 0 then return ret end 
    gG.dollar_buffer = (gG.dollar_buffer or 0) + ret
    gm.E_MANAGER:enqueue_event({ func = (function() gm.GAME.dollar_buffer = 0; return Y end) })
    return ret
end

---------------------------------------
--- print me
---------------------------------------
function Card:print_me() print(G.debugger.time_stamp(), self.base.suit, self.base.value) end

end