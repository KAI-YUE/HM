local Rsuits = require("HMGplay.cards.card_data.suits")

local max, min = math.max, math.min

local Y, N = true, false 


return function (Card)
-------------------------------------------------
--- is suit
-------------------------------------------------
function Card:is_suit(suit, bypass_debuff, flush_calc)
    local gm, ab, base, _d = self.gm, self.ability, self.base, self.debuff
    local name, effect, _s = ab.name, ab.effect, base.suit

    if flush_calc then
        if effect == "Stone Card" then return N end
        if name == "Wild Card" and not _d then return Y end
        return _s == suit
    end

    if _d and not bypass_debuff then return N end
    if effect == "Stone Card" then return N end
    if name   == "Wild Card"  then return Y end
    return _s == suit
end

------------------------------------------
--- Set base 
------------------------------------------
function Card:set_base(card, initial)
    local gm, cfg     = self.gm, self.config
    local base, card  = self.base, card or {}

    cfg.card = card
    
    if next(card) then self:set_sprites(nil, card) end

    local _n, _s, _r, _rl, _v = card.name, card.suit, tostring(card.rank), card.rank_label, card.value
    self.base  = { name = _n, suit = _s, rank = _r, rank_label = _rl, value = _v, nominal = 0, suit_nominal = 0, face_nominal = 0,  times_played = 0 }
    local base = self.base

    base.nominal, base.id = _v, _v
    if initial then base.original_value = _v end

    if     _s == "diamond" then base.suit_nominal = 0.01; base.suit_nominal_original = suit_base or 0.001 
    elseif _s == "club"    then base.suit_nominal = 0.02; base.suit_nominal_original = suit_base or 0.002 
    elseif _s == "heart"   then base.suit_nominal = 0.03; base.suit_nominal_original = suit_base or 0.003 
    elseif _s == "spade"   then base.suit_nominal = 0.04; base.suit_nominal_original = suit_base or 0.004 end 

    if initial then return end 
    if self.playing_card then handle_unlock_request(gm, { type = "modify_deck" }) end
end

------------------------------------------
--- mod rank
------------------------------------------
function Card:mod_rank(delta)
    local base = self.base
    if not base then return end

    local cur_rank  = tonumber(base.value or base.id or base.rank) or 1
    local next_rank = ((cur_rank - 1 + (delta or 0)) % 10) + 1
    base.rank       = tostring(next_rank)
    base.rank_label = nil
    base.value      = next_rank
    base.name       = base.rank.."of"..base.suit
    
    print(base.suit)

    self:set_base(base)
    self:build_front_canvas()
    self:sync_field_presentation()
end

------------------------------------------
--- mod suit
------------------------------------------
function Card:mod_suit(suit_name)
    local base = self.base
    if not base or not Rsuits.code_names[suit_name] then return end

    local cur_rank  = tonumber(base.value or base.id or base.rank) or 1
    local next_card = {   suit = suit_name, rank = tostring(cur_rank), rank_label = base.rank_label,
        value = cur_rank, name = tostring(cur_rank).."of"..suit_name,
    }

    self:set_base(next_card)
    self:build_front_canvas()
    self:sync_field_presentation()
end

end
