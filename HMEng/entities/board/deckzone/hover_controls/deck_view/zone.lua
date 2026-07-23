local Tree     = require("HMEng.ui_actors.common.tree")
local Body     = require("HMui.menu.data.pages._4_deck_preview_page.preview_body")
local Data     = require("HMui.menu.data.pages._4_deck_preview_page.preview_layout")
local RNG      = require("HMfns.utils.math.rng_utils")
local CardZone = require("HMEng.entities.board.cardzone")

local max, min = math.max, math.min
local Y, N = true, false

local M = {}

--------------------------------------------------
--- suit row layout
--------------------------------------------------
--- Helper: is_dragging | card_jitter 
local function is_dragging(card)        return card.states.drag.is end
local function card_jitter(card, axis)  return 2*RNG.hash_string32(tostring(card.ID or card.sort_id or 0) .. ":deck_preview:" .. axis) - 1 end

--- Helper: card_lift
local function card_lift(card, cfg)
    local st, lift = card.states, 0
    if st.hover.is or st.focus.is   then lift = lift - cfg.preview_hover_lift end
    if card.highlighted             then lift = lift - cfg.preview_highlight_lift end
    return lift
end

--- Helper: shadow_parallax
local function shadow_parallax(card)
    local sp = card.shadow_parallax
    sp.x, sp.y = 1.2, -1.3
end

--- Helper: sync zone pose | preview target
local function sync_zone_pose(zone)
    local row, offset = zone.row_widget, zone.row_offset
    if row then zone.T.x, zone.T.y = row.T.x + offset.x, row.T.y + offset.y; zone.VT.x, zone.VT.y = zone.T.x, zone.T.y end
end
local function preview_target(zone, card, idx, count)
    local T, cfg = zone.T, zone.config
    local pad_x, pad_y = cfg.preview_pad_x, cfg.preview_pad_y
    local scale = min(cfg.preview_max_scale, (T.h - 2*pad_y)/max(zone.card_h, 0.01))
    local card_w, card_h = zone.card_w*scale, zone.card_h*scale
    local available = max(0, T.w - 2*pad_x - card_w)
    local stride = count > 1 and min(card_w*(1 - cfg.preview_overlap_x), available/(count - 1)) or 0
    return {
        x = T.x + pad_x + (idx - 1)*stride + card_jitter(card, "x")*cfg.preview_jitter_x,
        y = T.y + 0.5*(T.h - card_h) + card_jitter(card, "y")*cfg.preview_jitter_y,
        w = card_w, h = card_h, r = card_jitter(card, "r")*cfg.preview_jitter_r, scale = 1,
    }
end

--- Helper: align_cards
local function align_cards(zone)
    local cards = zone.cards;        if not cards or #cards == 0 then return end
    sync_zone_pose(zone)

    for idx, card in ipairs(cards) do
        card.rank = idx
        if is_dragging(card) then goto continue end

        local target = preview_target(zone, card, idx, #cards)
        target.y = target.y + card_lift(card, zone.config)

        card.T.r, card.T.scale = target.r, 1
        if card.deck_preview_flip_reveal then
            card.T.x, card.T.y, card.T.w, card.T.h = target.x, target.y, target.w, target.h
            if card.wake_move then card:wake_move() end
        else card:hard_set_T(target.x, target.y, target.w, target.h) end
        shadow_parallax(card)
        ::continue::
    end
end

--- Helper: row_visible | sync_card_visibility
local function row_visible(zone)
    local row = zone.row_widget;                    if not (row and not row.REMOVED and row.states.visible) then return N end
    if row.scrollable_item_visible ~= nil then return row.scrollable_item_visible end
    local slot, visible = row.scrollable_entry_slot, row.parent and row.parent.config.visible_count; if not (slot and visible) then return N end
    return slot >= 1 and slot <= visible
end
local function sync_card_visibility(zone)  local visible, clip = row_visible(zone), zone.row_widget and zone.row_widget.parent; for _, card in ipairs(zone.cards or {}) do card.states.visible, card.scrollable_clip_parent = visible, clip end end

--- Helper: draw_cards
local function draw_cards(zone)
    sync_zone_pose(zone)
    sync_card_visibility(zone)
    align_cards(zone)
    return row_visible(zone)
end

--- Helper: row_zone
local function row_zone(deck, row, suit)
    local gm, zcfg = deck.gm, Data.zone
    local zone = CardZone(gm, 0, 0, max(0.1, row.T.w - zcfg.T.w_trim), row.T.h, {
        type              = "deck_preview_suit",    card_limit        = 52,                highlighted_limit  = 52,
        draw_cards        = draw_cards,             align_cards       = align_cards,       live_layout        = Y,      card_shadow_parallax    = shadow_parallax,
        card_shadow_heights = zcfg.shadow_heights,
        preview_pad_x     = zcfg.pad_x,              preview_pad_y     = zcfg.pad_y,         preview_overlap_x  = zcfg.overlap_x,  preview_max_scale       = zcfg.max_scale,
        preview_jitter_x  = zcfg.jitter_x,           preview_jitter_y  = zcfg.jitter_y,      preview_jitter_r   = zcfg.jitter_r,
        preview_hover_lift = zcfg.hover_lift,        preview_highlight_lift = zcfg.highlight_lift,
    })

    zone.suit, zone.row_widget, zone.row_offset, zone.scrollable_clip_parent = suit, row, zcfg.T, row.parent
    zone.can_highlight = function() return Y end
    zone:set_role({ role_type = "Minor", major = row, offset = { x = zcfg.T.x, y = zcfg.T.y }, xy_bond = "Strong", wh_bond = "Weak", r_bond = "Strong", scale_bond = "Strong" })
    zone._post_update = sync_card_visibility
    return zone
end

--------------------------------------------------
--- create
--------------------------------------------------
function M.create(deck, panel, suits)
    local preview  = { zones = {}, by_suit = {}, panel = panel }
    local root     = panel and panel.widget

    for _, suit in ipairs(suits or {}) do
        local row = Tree.find_child_by_id(root, Body.row_id_prefix .. suit)
        if not row then goto continue end
        local zone = row_zone(deck, row, suit)
        zone.parent = panel
        zone.preview_row_draw = function() zone:draw() end
        row.scrollable_overlay_draw = zone.preview_row_draw
        preview.zones[#preview.zones + 1], preview.by_suit[suit] = zone, zone
        ::continue::
    end
    
    preview.cursor_context_allows_node = function(node)
        local zone = node and node.zone
        return zone and preview.by_suit[zone.suit] == zone or N
    end
    
    if panel then panel.cursor_context_allows_node = preview.cursor_context_allows_node end
    function preview:remove() M.remove(self) end
    return preview
end

--------------------------------------------------
--- remove
--------------------------------------------------
function M.remove(preview)
    local panel = preview and preview.panel
    if panel and panel.cursor_context_allows_node == preview.cursor_context_allows_node then panel.cursor_context_allows_node = nil end

    for idx = #(preview and preview.zones or {}), 1, -1 do
        local zone = preview.zones[idx]
        if zone.row_widget and zone.row_widget.scrollable_overlay_draw == zone.preview_row_draw then zone.row_widget.scrollable_overlay_draw = nil end
        for _, card in ipairs(zone.cards or {}) do card.scrollable_clip_parent = nil end
        if not zone.REMOVED then zone:remove() end
        table.remove(preview.zones, idx)
    end
    if preview then preview.by_suit, preview.panel = {}, nil end
end

return M
