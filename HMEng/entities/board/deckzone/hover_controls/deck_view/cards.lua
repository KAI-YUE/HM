local Y, N  = true, false
local Body  = require("HMui.menu.data.pages._4_deck_preview_page.preview_body")
local Ranks = require("HMGplay.cards.card_data.hand_ranks")

local M = {}

--------------------------------------------------
--- card snapshot
--------------------------------------------------
--- Helper: copy_cards
local function copy_cards(cards)
    local out = {}
    for _, card in ipairs(cards or {}) do out[#out + 1] = card end
    return out
end

--- Helper: full_deck_cards
local function full_deck_cards(gm, deck)
    local cards = copy_cards(gm.run_card_id);       if #cards > 0 then return cards end
    local seen = {}
    for _, zone in ipairs({ deck, gm.hand, gm.play, gm.discard }) do
        for _, card in ipairs((zone and zone.cards) or {}) do if not seen[card] then seen[card], cards[#cards + 1] = Y, card end; end
    end
    return cards
end

--- Helper: snapshot_card
local function snapshot_card(session, card)
    local st = card.states
    session.card_zones[card]   = card.zone
    session.card_faces[card]   = { facing = card.facing, sprite_facing = card.sprite_facing }
    session.card_poses[card]   = { x = card.T.x, y = card.T.y, w = card.T.w, h = card.T.h, r = card.T.r, scale = card.T.scale }
    session.card_tilt_shadows[card] = card.tilt_shadow
    session.card_states[card]  = {
        drag = st.drag.can, collide = st.collide.can, hover = st.hover.can, click = st.click.can,
        visible = st.visible, highlighted = card.highlighted, interaction_layer = card.interaction_layer,
    }
end

--- Helper: snapshot_zone
local function snapshot_zone(session, zone)
    if not zone or session.zone_cards[zone] then return end
    session.zone_cards[zone] = copy_cards(zone.cards)
    session.zone_highlighted[zone] = copy_cards(zone.highlighted)
end

---__________________________________
--- main: snapshot
---__________________________________
function M.snapshot(deck, session)
    local gm = deck.gm
    session.pages = {
        full_deck = full_deck_cards(gm, deck),
        remaining = copy_cards(deck.cards),
        discard = copy_cards(gm.discard and gm.discard.cards),
    }
    for _, card in ipairs(session.pages.full_deck) do if card.zone and card.zone.cards then snapshot_zone(session, card.zone); snapshot_card(session, card) end; end
end

-------------------------------------
--- suits
-------------------------------------
function M.suits(cards) return Body.suits(cards) end

--- Helper: rank sort value | rank less
local function rank_sort_value(card) local base = card and card.base or {}; return Ranks.sort_values[tostring(base.rank)] or math.huge end
local function rank_less(a, b)
    local ar, br = rank_sort_value(a), rank_sort_value(b)
    if ar ~= br then return ar < br end
    return (a.sort_id or 0) < (b.sort_id or 0)
end

--------------------------------------------------
--- place
--------------------------------------------------
--- Helper: clear_preview
local function clear_preview(preview)
    for _, zone in ipairs((preview and preview.zones) or {}) do
        for idx = #zone.cards, 1, -1 do zone.cards[idx]:detach_from_zone(); table.remove(zone.cards, idx) end
        zone:mark_card_layout_dirty()
    end
end

--- Helper: restore_card_zone
local function restore_card_zone(zone, card)
    if zone.is_deck and zone:is_deck() then
        card:promote_to_deck_card()
        card:_set_base_zone(zone)
        if zone.projected_quad_source then zone:assign_quad(nil, card) end
        return
    end
    if zone.projector then card:promote_to_field_card(); card:set_zone(zone); return end
    card:demote_to_card()
    card:_set_base_zone(zone)
end

--- Helper: restore_card_state
local function restore_card_state(session, card)
    local saved  = session.card_states[card];             if not saved then return end
    local st     = card.states
    st.drag.can,  st.collide.can    = saved.drag,    saved.collide
    st.hover.can, st.click.can      = saved.hover,   saved.click
    st.visible,   card.highlighted  = saved.visible, saved.highlighted
    card.interaction_layer          = saved.interaction_layer
end

--- helper: restore_zone_cards
local function restore_zone_cards(session)
    for zone, cards in pairs(session.zone_cards) do
        zone.cards = copy_cards(cards)
        zone.highlighted = copy_cards(session.zone_highlighted[zone])
        for _, card in ipairs(zone.cards) do
            if not card.REMOVED then
                restore_card_zone(zone, card)
                restore_card_state(session, card)
            end
        end
        zone:set_zone_sts()
        zone:align_cards()
    end
end

--- Helper: detach_page_cards
local function detach_page_cards(session, cards)
    local selected = {}
    for _, card in ipairs(cards or {}) do selected[card] = Y end
    for zone, zone_cards in pairs(session.zone_cards) do
        local kept = {}
        for _, card in ipairs(zone_cards) do
            if selected[card] then card:detach_from_zone()
            elseif not card.REMOVED then kept[#kept + 1] = card end
        end
        zone.cards, zone.highlighted = kept, {}
        zone:set_zone_sts()
        zone:align_cards()
    end
end

---_________________________________
--- main: place 
---_________________________________
function M.place(session, cards)
    clear_preview(session.preview)
    restore_zone_cards(session)
    detach_page_cards(session, cards)

    for _, card in ipairs(cards or {}) do
        if card.REMOVED or not session.card_zones[card] then goto continue end 
        local suit = tostring((card.base and card.base.suit) or "other")
        local zone = session.preview.by_suit[suit];        if not zone then goto continue end

        card.facing, card.sprite_facing, card.flipping = "front", "front", nil
        card.highlighted, card.tilt_shadow = N, N
        
        card:demote_to_card()
        zone.cards[#zone.cards + 1] = card
        card:set_zone(zone)
        
        card.states.drag.can,  card.states.collide.can = Y, Y
        card.states.hover.can, card.states.click.can   = Y, Y
        card.interaction_layer                         = card.Ctrl.cursor_context.layer
        
        ::continue::
    end
    for _, zone in ipairs(session.preview.zones) do table.sort(zone.cards, rank_less); zone:align_cards(); zone:_post_update(0) end
end

-----------------------------------------
--- restore
-----------------------------------------
--- helper: restore_presentation
local function restore_presentation(session, card)
    local face, pose, saved_st = session.card_faces[card], session.card_poses[card], session.card_states[card]
    if face then card.facing, card.sprite_facing, card.flipping = face.facing, face.sprite_facing, nil end
    if saved_st then restore_card_state(session, card) end
    card.tilt_shadow = session.card_tilt_shadows[card]
    if pose then
        card.T.r, card.T.scale = pose.r, pose.scale
        card:hard_set_T(pose.x, pose.y, pose.w, pose.h)
    end
    card:sync_field_presentation()
end

---________________________________
--- main: restore
---________________________________
function M.restore(session)
    clear_preview(session.preview)
    restore_zone_cards(session)
    for card in pairs(session.card_zones) do if not card.REMOVED then restore_presentation(session, card) end end
end

return M
