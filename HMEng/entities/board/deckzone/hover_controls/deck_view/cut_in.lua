local RNG         = require("HMfns.utils.math.rng_utils")
local Timeline    = require("HMui.menu.data.pages._4_deck_preview_page.anims.timeline")
local Cards       = require("HMEng.entities.board.deckzone.hover_controls.deck_view.cards")
local FadeTree    = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets.fade_tree")
local AnimUtils   = require("HMfns.animate.transitions.anim_utils")
local Visibility  = require("HMEng.entities.board.deckzone.hover_controls.deck_view.visibility")

local Y, N = true, false

local M = {}

local _queue = "deck_preview_cut_in"
local T_time = Timeline.cut_in

--------------------------------------------------
--- event helpers
--------------------------------------------------
--- Helper: clear queue | after
local function clear_queue(gm)       local EM = gm and gm.E_MANAGER; if EM and EM.queues[_queue] then EM:clear_queue(_queue) end end
local function after(gm, delay, fn)  return AnimUtils.after(gm, delay, fn, _queue) end

--------------------------------------------------
--- page helpers
--------------------------------------------------
--- Helper: set child alpha | fade children | restore children
local function set_child_alpha(children, alpha)       for _, child in ipairs(children or {}) do FadeTree.set_tree_alpha(child, alpha) end end
local function fade_children(gm, children, duration)  for _, child in ipairs(children or {}) do FadeTree.fade_tree_in(child, gm, duration) end end
local function restore_children(children)             for _, child in ipairs(children or {}) do FadeTree.fade_tree_in(child, nil, 0) end end

--------------------------------------------------
--- card helpers
--------------------------------------------------
--- Helper: card interaction
local function set_interaction(card, enabled)
    local st = card.states
    st.drag.can, st.collide.can, st.hover.can, st.click.can = enabled, enabled, enabled, enabled
    if not enabled then st.drag.is, st.hover.is, st.click.is = N, N, N end
end

--- Helper: pause visual children 
local function pause_visual_children(entry)
    local saved = {}
    
    local function visit(children)
        for _, child in pairs(children or {}) do
            saved[#saved + 1]       = { child = child, created_on_pause = child.created_on_pause }
            child.created_on_pause  = Y
            if child.wake_move then child:wake_move() end
            visit(child.children)
        end
    end

    visit(entry.card.children)
    entry.pause_visual_children = saved
end

--- Helper: restore_visual_children
local function restore_visual_children(entry)
    for _, saved in ipairs(entry.pause_visual_children or {}) do if not saved.child.REMOVED then saved.child.created_on_pause = saved.created_on_pause end end
    entry.pause_visual_children = nil
end

--- Helper: live state | live entry
local function live_state(session, token)        return session.cut_in and session.cut_in.token == token end
local function live_entry(session, token, entry) return live_state(session, token) and not entry.card.REMOVED end

--------------------------------------------------
--- back layout
--------------------------------------------------
--- Helper: prepare back card
local function prepare_back_card(card)
    local st, wh, back = card.states, card.motion.wh, card.children.back
    local entry = {
        card             = card,                           created_on_pause  = card.created_on_pause,
        back_draw_alpha  = back and back.draw_alpha,       

        pinch_in_dur     = wh.pinch_in_dur,                pinch_out_dur     = wh.pinch_out_dur,

        --- interaction setting 
        interaction = { drag = st.drag.can, collide = st.collide.can, hover = st.hover.can, click = st.click.can },
    }

    card.created_on_pause, card.deck_preview_flip_reveal  = Y,       Y
    card.facing,           card.sprite_facing             = "back", "back"
    card.pinch.x,          card.pinch_transition          = N,      nil
    st.dealing.is,         card.flipping                  = N,      nil 
    wh.pinch_in_dur,       wh.pinch_out_dur               = T_time.flip_in_duration, T_time.flip_out_duration

    if back then back.draw_alpha = 0 end
    set_interaction(card, N)
    pause_visual_children(entry)
    
    if card.wake_move then card:wake_move() end
    return entry
end

--- Helper: randomized entries
local function randomized_entries(preview, seed)
    local entries = {}
    for _, zone in ipairs((preview and preview.zones) or {}) do for _, card in ipairs(zone.cards or {}) do entries[#entries + 1] = prepare_back_card(card) end; end
    table.sort(entries, function(a, b)
        local ak = RNG.hash_string32(tostring(a.card.ID or a.card.sort_id or 0) .. ":deck_preview_flip:" .. seed)
        local bk = RNG.hash_string32(tostring(b.card.ID or b.card.sort_id or 0) .. ":deck_preview_flip:" .. seed)
        return ak == bk and (a.card.sort_id or 0) < (b.card.sort_id or 0) or ak < bk
    end)
    return entries
end

--------------------------------------------------
--- flip reveal
--------------------------------------------------
--- Helper: flip entry | finish entry
local function flip_entry(session, token, entry)
    if not live_entry(session, token, entry) then return Y end
    
    local card = entry.card
    card.states.dealing.is = Y

    if card.facing == "back" and not card.flipping then card:flip() end
    return Y
end
local function finish_entry(entry)
    local card       = entry.card;                          if card.REMOVED then return end
    local wh, saved  = card.motion.wh, entry.interaction

    card.created_on_pause,         card.states.dealing.is  = entry.created_on_pause, N
    card.deck_preview_flip_reveal, card.flipping           = nil,                    nil
    card.facing,                   card.sprite_facing      = "front",                "front"
    card.pinch.x,                  card.pinch_transition   = N,                      nil
    wh.pinch_in_dur,               wh.pinch_out_dur        = entry.pinch_in_dur,     entry.pinch_out_dur
    
    if card.children.back then card.children.back.draw_alpha = entry.back_draw_alpha end
    restore_visual_children(entry)
    
    card.states.drag.can,  card.states.collide.can  = saved.drag, saved.collide
    card.states.hover.can, card.states.click.can    = saved.hover, saved.click
end

--- Helper: schedule reveal
local function schedule_reveal(gm, session, token, entries)
    local flip_time, last_delay = T_time.flip_in_duration + T_time.flip_out_duration, 0
    
    for idx, entry in ipairs(entries) do
        local delay, scheduled = (idx - 1)*T_time.flip_stagger, entry
        last_delay = delay
        after(gm, delay,             function() return flip_entry(session, token, scheduled) end)
        after(gm, delay + flip_time, function() if live_entry(session, token, scheduled) then finish_entry(scheduled) end; return Y end)
    end
    
    after(gm, last_delay + flip_time + T_time.finish_padding, function() if live_state(session, token) then session.cut_in = nil end; return Y end)
end

--- Helper: prepare back layout 
local function prepare_back_layout(deck, session, state)
    local gm = deck.gm
    
    Cards.place(session, session.pages[session.page_key])
    Visibility.hide(gm, session)

    gm.deck_preview_preserve_source = nil
    state.entries = randomized_entries(session.preview, state.flip_seed)
    
    for _, entry in ipairs(state.entries) do
        local back, target_alpha = entry.card.children.back, entry.back_draw_alpha or 1
        if back then after(gm, T_time.back_fade_start, function() AnimUtils.ease(gm, back, "draw_alpha", target_alpha, T_time.back_fade_duration, "sine", _queue); return Y end) end
    end
end

--- Helper: begin_reveal
local function begin_reveal(deck, session, token)
    if not live_state(session, token) then return Y end
    local state = session.cut_in
    schedule_reveal(deck.gm, session, token, state.entries)
    return Y
end

--------------------------------------------------
--- public lifecycle
--------------------------------------------------
---______________________________
--- main: cancel
---______________________________
function M.cancel(session)
    local state = session and session.cut_in; if not state or not session.page_panel then return end

    local gm = session.page_panel.gm
    clear_queue(gm)

    gm.deck_preview_preserve_source = nil
    session.cut_in = nil

    if session.page_panel.widget then session.page_panel.widget.fx_mask = 0 end
    if session.page_panel.config then session.page_panel.config.underlay_alpha = T_time.snapshot_alpha_end end
    restore_children(state.children)
    for _, entry in ipairs(state.entries or {}) do finish_entry(entry) end
end

---______________________________
--- main: start
---______________________________
function M.start(deck, session)
    if not (deck and session and session.preview and session.page_panel) then return end
    M.cancel(session)

    local gm, widget = deck.gm, session.page_panel.widget
    local children, token = widget.page_child_widgets or {}, (session.cut_in_token or 0) + 1
    local flip_seed = tostring((gm._T and gm._T.real_s) or token)

    session.cut_in_token, session.cut_in = token, { token = token, entries = {}, children = children, flip_seed = flip_seed }

    widget.fx_mask = 1
    session.page_panel.config.underlay_alpha = T_time.snapshot_alpha_start
    set_child_alpha(children, 0)
    prepare_back_layout(deck, session, session.cut_in)
    
    after(gm, T_time.page_wipe_start, function() if live_state(session, token) then AnimUtils.ease(gm, widget, "fx_mask", 0, T_time.page_wipe_duration, "sine", _queue) end; return Y end)
    after(gm, T_time.snapshot_fade_start, function() if live_state(session, token) then AnimUtils.ease(gm, session.page_panel.config, "underlay_alpha", T_time.snapshot_alpha_end, T_time.snapshot_fade_duration, "sine", _queue) end; return Y end)
    after(gm, T_time.child_fade_start, function() if live_state(session, token) then fade_children(gm, children, T_time.child_fade_duration) end; return Y end)
    after(gm, T_time.flip_start, function() return begin_reveal(deck, session, token) end)
end

return M
