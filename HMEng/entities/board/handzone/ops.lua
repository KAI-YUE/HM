local RNG = require("HMfns.utils.math.rng_utils")
local TabUtils = require("HMfns.utils.table_utils")

local seeded_rand = RNG.seeded_random
local wipe = TabUtils.wipe

local Y, N = true, false

return function (HandZone)
--------------------------------------------------
--- hooks
--------------------------------------------------
--- Helpers: post emplace | can overfill on draw | can refill on size change 
function HandZone:_post_emplace(card, stay_flipped)
    if card.sprite_facing ~= "back" or stay_flipped then return end
    if card.defer_hand_flip then return end
    card:flip()
end
function HandZone:_can_overfill_on_draw()      return Y end
function HandZone:_can_refill_on_size_change() return Y end

--- Helper: prepare stay flipped 
function HandZone:_prepare_stay_flipped(stay_flipped)
    local Gmod = self.gm.GAME.modifiers
    if not Gmod.flipped_cards then return N end
    if seeded_rand("flipped_card") < 1/Gmod.flipped_cards then return Y end
    return stay_flipped
end

--- Helper: post update 
function HandZone:_post_update(dt) for _, card in pairs(self.cards) do if card.ability.forced_selection and not self.highlighted[1] then self:add_to_highlighted(card) end end; end

--------------------------------------------------
--- saved alignment state
--------------------------------------------------
--- Helper: copy scalar table
local function copy_scalar_table(src)
    local out = {}
    for k, v in pairs(src or {}) do if type(v) ~= "table" then out[k] = v end end
    return out
end

function HandZone:save_alignment_state()
    return {
        fan_grab_angle_jitter_deg = copy_scalar_table(self.fan_grab_angle_jitter_deg),
        fan_grab_pad_by_index     = copy_scalar_table(self.fan_grab_pad_by_index),
    }
end

function HandZone:restore_alignment_state(alignment)
    alignment = alignment or {}
    self:clear_fan_anchor_cache()
    self.fan_grab_angle_jitter_deg = copy_scalar_table(alignment.fan_grab_angle_jitter_deg)
    self.fan_grab_pad_by_index     = copy_scalar_table(alignment.fan_grab_pad_by_index)
end

--------------------------------------------------
--- deck hover offset
--------------------------------------------------
function HandZone:deck_hover_y_offset()
    local cfg, deck = self.config or {}, self.gm.deck
    if not deck then return 0 end

    local h = deck.hover_t or 0
    if h <= 0 then return 0 end
    return (cfg.deck_hover_y_offset or (0.24*self.card_h))*h
end

--------------------------------------------------
--- fan cache management
--------------------------------------------------
function HandZone:clear_fan_grab_jitter()
    self.fan_grab_angle_jitter_deg  = wipe(self.fan_grab_angle_jitter_deg)
    self.fan_grab_pad_by_index      = wipe(self.fan_grab_pad_by_index)
end

function HandZone:clear_fan_anchor_cache()
    self.fan_anchor_x_by_size = wipe(self.fan_anchor_x_by_size)
    self.fan_anchor_y_by_size = wipe(self.fan_anchor_y_by_size)
end

end
