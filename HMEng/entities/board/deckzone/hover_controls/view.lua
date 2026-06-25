local DeckPreviewZone = require("HMEng.entities.board.deckpreviewzone")
local HMPanel         = require("HMEng.ui_actors.hm_panel")
local DeckPreviewPage = require("HMui.menu.data.pages.deck_preview_page")

local Y, N = true, false

return function (DeckZone)
--------------------------------------------------
--- deck view zone helpers
--------------------------------------------------
local function create_deck_view_zone(self, card_limit)
    local gm, RT = self.gm, self.gm._room.T
    local cfg    = self.config
    return DeckPreviewZone(gm, RT.x, RT.y, RT.w, RT.h, {
        type           = "deck_preview",                  card_limit          = card_limit,
        preview_pad_x  = cfg.deck_view_pad_x,             preview_pad_top     = cfg.deck_view_pad_top or 1.35,
        preview_pad_right = cfg.deck_view_pad_right,      preview_pad_bottom  = cfg.deck_view_pad_bottom,
        preview_overlap_x = cfg.deck_view_overlap_x,      preview_overlap_y   = cfg.deck_view_overlap_y,
        preview_max_scale = cfg.deck_view_max_scale,
    })
end

--------------------------------------------------
--- deck view card snapshot helpers
--------------------------------------------------
local function copy_cards(cards)
    local out = {}
    for _, card in ipairs(cards or {}) do out[#out + 1] = card end
    return out
end

local function full_deck_cards(gm, deck)
    local cards = copy_cards(gm.run_card_id)
    if #cards > 0 then return cards end

    local seen = {}
    for _, zone in ipairs({ deck, gm.hand, gm.play, gm.discard }) do
        for _, card in ipairs((zone and zone.cards) or {}) do
            if not seen[card] then
                seen[card] = Y
                cards[#cards + 1] = card
            end
        end
    end
    return cards
end

local function snapshot_card(session, card)
    local st = card.states
    session.card_zones[card] = card.zone
    session.card_faces[card] = { facing = card.facing, sprite_facing = card.sprite_facing }
    session.card_poses[card] = { x = card.T.x, y = card.T.y, w = card.T.w, h = card.T.h, r = card.T.r, scale = card.T.scale }
    session.card_states[card] = { drag = st.drag.can, collide = st.collide.can, hover = st.hover.can, click = st.click.can }
end

local function snapshot_zone(session, zone)
    if not zone or session.zone_cards[zone] then return end
    session.zone_cards[zone] = copy_cards(zone.cards)
    session.zone_highlighted[zone] = copy_cards(zone.highlighted)
end

local function snapshot_deck_view_cards(self, session)
    local gm = self.gm
    session.pages = {
        full_deck = full_deck_cards(gm, self),
        remaining = copy_cards(self.cards),
        discard = copy_cards(gm.discard and gm.discard.cards),
    }

    for _, card in ipairs(session.pages.full_deck) do
        if card.zone and card.zone.cards then
            snapshot_zone(session, card.zone)
            snapshot_card(session, card)
        end
    end
end

--------------------------------------------------
--- deck view card zone helpers
--------------------------------------------------
local function restore_card_zone(zone, card)
    if zone.is_deck and zone:is_deck() then
        card:promote_to_deck_card()
        card:_set_base_zone(zone)
        if zone.projected_quad_source then zone:assign_quad(nil, card) end
        return
    end
    if zone.projector then
        card:promote_to_field_card()
        card:set_zone(zone)
        return
    end
    card:demote_to_card()
    card:_set_base_zone(zone)
end

local function restore_zone_cards(session)
    for zone, cards in pairs(session.zone_cards) do
        zone.cards = copy_cards(cards)
        zone.highlighted = copy_cards(session.zone_highlighted[zone])
        for _, card in ipairs(zone.cards) do if not card.REMOVED then restore_card_zone(zone, card) end end
        zone:set_zone_sts()
        zone:align_cards()
    end
end

local function detach_page_cards(session, cards)
    local selected = {}
    for _, card in ipairs(cards or {}) do selected[card] = Y end

    for zone, zone_cards in pairs(session.zone_cards) do
        local kept = {}
        for _, card in ipairs(zone_cards) do
            if selected[card] then card:detach_from_zone()
            elseif not card.REMOVED then kept[#kept + 1] = card end
        end
        zone.cards = kept
        zone.highlighted = {}
        zone:set_zone_sts()
        zone:align_cards()
    end
end

--------------------------------------------------
--- deck view page data helpers
--------------------------------------------------
local function switch_page_hook(gm, source)
    local cfg = source and source.config
    local deck = gm and gm.deck
    if deck and cfg then return deck:switch_deck_view_page(cfg.deck_view_page_key) end
end

local function close_deck_view_hook(gm)
    local deck = gm and gm.deck
    if deck then return deck:close_deck_view() end
end

local function deck_view_page(self, selected)
    return DeckPreviewPage.build(self.gm, selected, {
        switch_page = switch_page_hook,
        close = close_deck_view_hook,
    })
end

--------------------------------------------------
--- deck view overlay helpers
--------------------------------------------------
local function create_deck_view_page_panel(self, selected)
    local gm = self.gm
    local page = deck_view_page(self, selected)
    page.type, page.can_collide, page.can_hover = "overlay_menu", Y, Y
    page.hit_area, page.can_click, page.can_drag = "world", N, N

    local panel = HMPanel(gm, page)
    panel.config = { no_esc = Y, underlay = N }
    gm.UI.overlay_menu = panel
    gm.CTRL:mod_cursor_context_layer(1)
    return panel
end

local function remove_deck_view_page_panel(gm, session)
    local panel = session.page_panel
    if gm.UI.overlay_menu == panel then gm.UI.overlay_menu = nil end
    if panel and not panel.REMOVED then panel:remove() end
    if session.cursor_context_open then gm.CTRL:mod_cursor_context_layer(-1) end
    if gm.mark_overlay_snapshot_dirty then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
end

--------------------------------------------------
--- deck view page switching helpers
--------------------------------------------------
local function clear_preview_cards(preview)
    for idx = #preview.cards, 1, -1 do preview:take_card(preview.cards[idx]) end
end

local function place_page_cards(session, cards)
    clear_preview_cards(session.preview)
    restore_zone_cards(session)
    detach_page_cards(session, cards)
    for _, card in ipairs(cards or {}) do
        if not card.REMOVED and session.card_zones[card] then
            card.facing, card.sprite_facing, card.flipping = "front", "front", nil
            session.preview:add_card(card)
            card:sync_field_presentation()
        end
    end
    session.preview:align_cards()
end

function DeckZone:switch_deck_view_page(page_key)
    local session = self.deck_view_session
    if not session or not session.pages[page_key] or session.page_key == page_key then return N end

    session.page_key = page_key
    place_page_cards(session, session.pages[page_key])
    if session.page_panel and not session.page_panel.REMOVED then
        session.page_panel:switch_stroked_page(deck_view_page(self, page_key), { delay = 0.22 })
    end
    return Y
end

--------------------------------------------------
--- character visibility helpers
--------------------------------------------------
local function hide_characters(gm, session)
    for _, chara in pairs((gm.R and gm.R.CHARA) or {}) do
        if chara.states then
            session.chara_visibility[chara] = chara.states.visible
            chara.states.visible = N
        end
    end
end

local function restore_characters(session)
    for chara, visible in pairs(session.chara_visibility) do
        if not chara.REMOVED and chara.states then chara.states.visible = visible end
    end
end

--------------------------------------------------
--- HUD visibility helpers
--------------------------------------------------
local function hide_hud_obj(session, obj)
    if not (obj and obj.states) then return end
    session.hud_visibility[obj] = obj.states.visible
    obj.states.visible = N
end

local function hide_hud(gm, session)
    hide_hud_obj(session, gm.HUD)
    hide_hud_obj(session, gm.HUD_blind)
    for _, tag in pairs(gm.HUD_tags or {}) do hide_hud_obj(session, tag) end
end

local function restore_hud(session)
    for obj, visible in pairs(session.hud_visibility) do
        if not obj.REMOVED and obj.states then obj.states.visible = visible end
    end
end

--------------------------------------------------
--- restore deck view helpers
--------------------------------------------------
local function restore_card_presentation(session, card)
    local face = session.card_faces[card]
    local pose = session.card_poses[card]
    local saved_st = session.card_states[card]
    if face then card.facing, card.sprite_facing, card.flipping = face.facing, face.sprite_facing, nil end
    if saved_st then
        local st = card.states
        st.drag.can, st.collide.can = saved_st.drag, saved_st.collide
        st.hover.can, st.click.can = saved_st.hover, saved_st.click
    end
    if pose then
        card.T.x, card.T.y, card.T.w, card.T.h = pose.x, pose.y, pose.w, pose.h
        card.T.r, card.T.scale = pose.r, pose.scale
        card:hard_set_T(pose.x, pose.y, pose.w, pose.h)
    end
    card:sync_field_presentation()
end

local function restore_deck_view_cards(session)
    clear_preview_cards(session.preview)
    restore_zone_cards(session)
    for card in pairs(session.card_zones) do if not card.REMOVED then restore_card_presentation(session, card) end end
end

local function remove_deck_view_ui(session)
    if not session.preview.REMOVED then session.preview:remove() end
end

--------------------------------------------------
--- main: view deck | close deck view
--------------------------------------------------
function DeckZone:view_deck()
    local gm = self.gm
    if self.deck_view_session or gm.UI.overlay_menu then return N end

    local field = gm.field
    local session = {
        card_zones = {}, card_faces = {}, card_poses = {}, card_states = {},
        zone_cards = {}, zone_highlighted = {}, chara_visibility = {}, hud_visibility = {},
        previous_state = gm.g_state,
        previous_pause = gm.SET.pause,
        field = field, field_visible = field and field.states.visible,
        page_key = "remaining",
    }
    snapshot_deck_view_cards(self, session)
    if #session.pages.full_deck == 0 then return N end
    session.preview = create_deck_view_zone(self, #session.pages.full_deck)

    self.deck_view_session = session
    gm.deck_preview = session.preview
    gm.VIEWING_DECK = Y
    gm.g_state = gm.g_states.viewing_deck
    gm.SET.pause = Y
    session.page_panel = create_deck_view_page_panel(self, session.page_key)
    session.cursor_context_open = Y
    gm.UI.deck_view_page = session.page_panel
    if field then field.states.visible = N end
    hide_characters(gm, session)
    hide_hud(gm, session)
    place_page_cards(session, session.pages[session.page_key])
    return Y
end

function DeckZone:close_deck_view()
    local gm, session = self.gm, self.deck_view_session
    gm.VIEWING_DECK = nil
    if not session then return N end

    restore_deck_view_cards(session)
    if session.field and not session.field.REMOVED then session.field.states.visible = session.field_visible end
    restore_characters(session)
    restore_hud(session)
    if gm.g_state == gm.g_states.viewing_deck then gm.g_state = session.previous_state end
    gm.SET.pause = session.previous_pause
    gm.deck_preview = nil
    gm.UI.deck_view_page = nil
    self.deck_view_session = nil
    remove_deck_view_page_panel(gm, session)
    remove_deck_view_ui(session)
    return Y
end
end
