local Gate     = require("HMEng.controller.input_gate")
local SND, TMR = require("HMfns.utils.sound_utils"), require("HMfns.systems.timer")
local C, EC    = require("HMfns.animate.color.color_const"), require("HMGplay.economy")
local Career   = require("HMfns.profiles.gallery.career") 

local play_clip = SND.play_clip
local update_career = Career.update_career
local add_money = EC.add_money 
local sleep     = TMR.sleep
local suspend   = Gate.suspend_interaction

local _ta  = "after"
local Y, N = true, false

return function (Card)
--------------------------------------------
--- Sell card 
--------------------------------------------
--- Helper: sell and unlock ctrl 
function Card:_sell_and_unlock_ctrl()
    local gm, zone = self.gm, self.zone;          sleep(gm, 0.2);       
    
    EC.add_money(gm, self.sell_cost)
    self:start_fx_mask({ C.GOLD });              sleep(gm, 0.3)
    update_career(gm, "c_cards_sold", 1);         local ab, gG, Ctrl   = self.ability, gm.GAME, gm.CTRL
    local Gb, EM = gG.blind, gm.E_MANAGER;        local C_locks, _area = Ctrl.locks, (zone == gm.jokers and "jokers") or "consumables"

    if ab.set == "Joker" then update_career(gm, "c_jokers_sold", 1) end
    if ab.set == "Joker" and Gb and Gb.name == "Verdant Leaf" then EM:enqueue_event({ func = function() Gb:disable(); return Y end }) end
    EM:enqueue_event({ trigger = _ta, delay = 0.3, blocking = N, func = function() EM:enqueue_event({ func = function() EM:enqueue_event({ func = function() C_locks.selling_card = nil; Ctrl:recall_cardarea_focus(gm, _area); return Y end}) return Y end}) return Y end}) 
    return Y
end 

--- Main 
function Card:sell_card()
    local gm = self.gm;                     local Ctrl = gm.CTRL 
    local C_locks = Ctrl.locks;             C_locks.selling_card = Y
    suspend(gm);                            local zone = self.zone
    
    Ctrl:save_cardarea_focus(zone == gm.jokers and "jokers" or "consumables")
    local ch, EM = self.children, gm.E_MANAGER
    if ch.use_button  then ch.use_button:remove();  ch.use_button  = nil end
    if ch.sell_button then ch.sell_button:remove(); ch.sell_button = nil end
    
    self:calculate_joker({ selling_self = Y })
    EM:enqueue_event({ trigger = _ta, delay = 0.2,func = function() self:jitter_me(0.3, 0.4);  return play_clip(gm, "coin2") end })
    EM:enqueue_event({ func = function() return self:_sell_and_unlock_ctrl() end })
end

--------------------------------------------
--- can sell card 
--------------------------------------------
function Card:can_sell_card(context)
    local gm = self.gm;                     local play = gm.play
    local Ctrl = gm.CTRL;             local gG, SET = gm.GAME, gm.SET

    if (play and #play.cards > 0) or (Ctrl.locked) or (gG.STOP_USE and gG.STOP_USE > 0) then return N end
    if (SET.tutorial_complete or gG.round_resets.ante > 1) then 
        local zone, ab = self.zone, self.ability
        if not zone or zone.config.type ~= "joker" or ab.eternal then return N end 
        return Y
    end
    return N
end

--------------------------------------------
--- calculate dollar bonus 
--------------------------------------------
function Card:calculate_dollar_bonus()
    if self.debuff then return end
    
    local ab = self.ability;                local set, extra, aname = ab.set, ab.extra, ab.name
    if set ~= "Joker" then return end

    if aname == "Golden Joker" then return extra end
    if aname == "Cloud 9" and ab.nine_tally and ab.nine_tally > 0 then return extra*(ab.nine_tally) end
    if aname == "Rocket" then return extra.dollars end

    local gG = self.gm.GAME
    if aname == "Satellite" then local _p = 0; for k, v in pairs(gG.consumable_usage) do if v.set == "Planet" then _p = _p + 1 end end; return _p  end
    if aname == "Delayed Gratification"  then 
        local cr = gG.current_round; 
        if cr.discards_used ~= 0 and cr.discards_left <= 0 then return end 
        return cr.discards_left * extra
    end
end

end