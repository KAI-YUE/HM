local Card  = require("HMEng.entities.card")
local Suits = require("HMGplay.cards.card_data.suits")

local M = {}

-----------------------------
--- new_foe_visual_card
----------------------------------
--- Helper: suit for value
local function _suit_for_value(value)
    local suits = Suits.abbrev or { "F" }
    local idx = ((tonumber(value) or 1) - 1)%#suits + 1
    return suits[idx] or "F"
end

--- Helper: base card
local function _base_card(value, suit)
    local rank      = tonumber(value) or 1
    local card_suit = suit or _suit_for_value(rank)
    return {
        suit       = card_suit,
        rank       = tostring(rank),
        rank_label = tostring(rank),
        value      = rank,
        name       = tostring(rank) .. "of" .. tostring(card_suit),
    }
end

--- Helper: FOE hand facing
local function _foe_hand_facing(battle) return battle.debug_battle and "front" or "back" end

--- Helper: set card facing
local function _set_card_facing(card, facing)
    if not card then return end
    card.facing, card.sprite_facing, card.flipping = facing, facing, nil
    card.pinch.x, card.pinch.y = false, false
    if facing == "front" and card.build_front_canvas then card:build_front_canvas() end
    if card.sync_field_presentation then card:sync_field_presentation() end
end

function M.new_foe_visual_card(battle, value, zone)
    local gm   = battle.gm
    local card = Card(gm, zone.T.x, zone.T.y, gm.card_w, gm.card_h, _base_card(value), gm.CMod.c_base, { facing = _foe_hand_facing(battle) })
    card.battle_foe_value = value
    return card
end

-----------------------------
--- reveal_foe_card
----------------------------------
function M.reveal_foe_card(card)
    _set_card_facing(card, "front")
    return card
end

-----------------------------
--- refresh_foe_deck_visual
----------------------------------
--- Helper: clear zone
local function _clear_zone(zone) while zone and zone.cards and zone.cards[1] do zone:take_card(zone.cards[1]):remove() end end

function M.refresh_foe_deck_visual(battle)
    local zone = battle.foe_deck_zone
    if not zone then return end
    _clear_zone(zone)

    local foe = battle.run.parties[2]
    if not (foe and foe.deck and #foe.deck > 0) then return end
    local gm = battle.gm
    local card = Card(gm, zone.T.x, zone.T.y, gm.card_w, gm.card_h, _base_card(1, "F"), gm.CMod.c_base, { facing = "back" })
    zone:add_card(card)
    zone:align_cards()
    card:sync_field_presentation()
    return card
end

-----------------------------
--- draw_foe_battle_card
----------------------------------
function M.draw_foe_battle_card(battle)
    local foe, zone = battle.run.parties[2], battle.foe_hand_zone
    if not (foe and foe.deck and zone) then return end
    if #zone.cards >= zone.config.card_limit or #foe.deck == 0 then return end

    local value = table.remove(foe.deck)
    local card = M.new_foe_visual_card(battle, value, zone)
    zone:add_card(card)
    zone:align_cards()
    card:sync_field_presentation()
    M.refresh_foe_deck_visual(battle)
    return card
end

-----------------------------
--- fill_foe_hand
----------------------------------
function M.fill_foe_hand(battle, target_count)
    local zone = battle.foe_hand_zone
    if not zone then return end
    target_count = target_count or zone.config.card_limit
    while #zone.cards < target_count do
        local card = M.draw_foe_battle_card(battle)
        if not card then break end
    end
    M.refresh_foe_deck_visual(battle)
end

return M
