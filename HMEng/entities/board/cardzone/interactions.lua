local RNG       = require("HMfns.utils.math.rng_utils")
local TabUtils  = require("HMfns.utils.table_utils")

local shuffle,     _pick  = TabUtils.shuffle_in_place, TabUtils.random_pick
local seeded_rand, _hash  = RNG.seeded_random, RNG.hash_unit32

local Y, N = true, false

return function (CardZone)
--------------------------------------------------
--- hooks
--------------------------------------------------
function CardZone:_remove_default_card(_cards) return _cards[1] end
function CardZone:_remove_discard_card(_cards) return _cards[#_cards] end

--------------------------------------------------
--- remove card 
--------------------------------------------------
--- Helper: preprocess before remove
local function _preprocess(gm, card)
    if card.sprite_facing == "front" then 
        card:flip(); 
        gm.E_MANAGER:enqueue_event({ trigger = "after", delay = 0.15, blockable = N, func = function() card:flip(); return Y; end} )
    end
end

---_____________________________
--- main: remove card
---_____________________________
function CardZone:remove_card(card, discarded_only)
    local _sc, cfg  = self.cards, self.config;           if not _sc then return end
    local gm, type  = self.gm, cfg.type;                 local _cards = discarded_only and {} or _sc
    if discarded_only then for k, v in ipairs(_sc) do local ab = v.ability; if ab.discarded then push(_cards, v) end end end
    
    if type == "discard" then card = card or self:_remove_discard_card(_cards)
    else card = card or self:_remove_default_card(_cards) end

    for i = #_sc, 1, -1 do
        if _sc[i] == card then
            _preprocess(gm, card)
            card:detach_from_zone()
            table.remove(self.cards, i)
            self:remove_from_highlighted(card, Y);  break
        end
    end
    self:set_zone_sts()
    self:mark_card_layout_dirty()
    return card
end

----------------------------------------------------
--- draw card from 
----------------------------------------------------
--- Helper: adhoc stay_flipped
local function _adhoc_stay_flipped(self, gm, stay_flipped)
    return self:_prepare_stay_flipped(stay_flipped)
end

---______________________________
--- main: draw card from
---______________________________
function CardZone:draw_card_from(zone, stay_flipped, discarded_only)
    if not zone:is(CardZone) then return end 
    local cfg, gm = self.config, self.gm

    if #self.cards>= cfg.card_limit and not self:_can_overfill_on_draw() then return end 
    local card = zone:remove_card(nil, discarded_only)
    if not card then return end 
    
    if zone == gm.discard then card.T.r = 0 end
    stay_flipped = _adhoc_stay_flipped(self, gm, stay_flipped)
    card.defer_hand_flip = self:is_hand() and card.sprite_facing == "back" and not stay_flipped

    self:emplace(card, stay_flipped)
    return card
end

---------------------------------------------------------------
--- shuffle
---------------------------------------------------------------
function CardZone:shuffle(_seed) shuffle(self.cards, _hash(self.gm, _seed or "shuffle")); self:set_zone_sts(); self:mark_card_layout_dirty() end

end
