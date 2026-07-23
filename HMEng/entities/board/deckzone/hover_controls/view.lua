local _view_dir = "HMEng.entities.board.deckzone.hover_controls.deck_view."

local SnapshotTrans = require("HMui.menu.transitions.snapshot")
local Cards      = require(_view_dir .. "cards")
local CutIn      = require(_view_dir .. "cut_in")
local Page       = require(_view_dir .. "page")
local Visibility = require(_view_dir .. "visibility")
local Zone       = require(_view_dir .. "zone")

local Y, N = true, false

return function (DeckZone)
--------------------------------------------------
--- snapshot underlay
--------------------------------------------------
--- Helper: capture snapshot underlay
local function capture_snapshot_underlay(gm, session)
    local canvas = SnapshotTrans.capture_canvas(gm);        if not canvas then return end
    gm.overlay_bg_canvas, gm.overlay_bg_snapshot_dirty = canvas, N
    session.snapshot_underlay = canvas
end

--------------------------------------------------
--- switch deck view page
--------------------------------------------------
function DeckZone:switch_deck_view_page(page_key)
    local session = self.deck_view_session
    if not session or not session.pages[page_key] or session.page_key == page_key then return N end
    CutIn.cancel(session)
    Visibility.hide(self.gm, session)
    session.page_key = page_key
    Cards.place(session, session.pages[page_key])
    Page.select(session.page_panel, page_key)
    return Y
end

--------------------------------------------------
--- view deck
--------------------------------------------------
---______________________________
--- main: view_deck
---______________________________
function DeckZone:view_deck()
    local gm = self.gm
    if self.deck_view_session or gm.UI.overlay_menu then return N end
    local session = {
        card_zones = {}, card_faces = {}, card_poses = {}, card_states = {}, card_tilt_shadows = {},
        zone_cards = {}, zone_highlighted = {}, visibility = {},
        previous_state = gm.g_state, previous_pause = gm.SET.pause,
        page_key = Page.default_key,
    }
    Cards.snapshot(self, session)
    if #session.pages.full_deck == 0 then return N end
    session.suits = Cards.suits(session.pages.full_deck)
    capture_snapshot_underlay(gm, session)

    self.deck_view_session = session
    gm.g_state, gm.SET.pause = gm.g_states.viewing_deck, Y
    session.page_panel = Page.create(self, session.page_key, session.suits)
    session.preview = Zone.create(self, session.page_panel, session.suits)
    gm.deck_preview, gm.VIEWING_DECK = session.preview, Y
    session.cursor_context_open = Y
    gm.UI.deck_view_page = session.page_panel
    CutIn.start(self, session)
    return Y
end

--------------------------------------------------
--- close deck view
--------------------------------------------------
function DeckZone:close_deck_view()
    local gm, session = self.gm, self.deck_view_session
    
    gm.VIEWING_DECK = nil;              if not session then return N end
    
    CutIn.cancel(session)
    Cards.restore(session)
    
    Visibility.restore(session)
    if gm.g_state == gm.g_states.viewing_deck then gm.g_state = session.previous_state end
    
    gm.SET.pause = session.previous_pause
    gm.deck_preview, gm.UI.deck_view_page, self.deck_view_session = nil, nil, nil
    Zone.remove(session.preview)
    Page.remove(gm, session)
    return Y
end

end
