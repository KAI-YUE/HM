local State      = require("HMGplay.run_flow.game_run.battle.state")
local BattleLog  = require("HMGplay.run_flow.game_run.battle.log")
local Resolution = require("HMGplay.run_flow.game_run.battle.resolution")
local Turns      = require("HMGplay.run_flow.game_run.battle.turns")

local Y, N = true, false

local M = {}

-----------------------------
--- snap_dragged_card
----------------------------------
--- Helper: remove from zone
local function _remove_from_zone(card)
    local zone = card and card.zone
    if not zone then return end
    if zone.take_card then return zone:take_card(card), zone end
    if zone.remove_card then return zone:remove_card(card), zone end
end

--- Helper: set staged card state
local function _set_staged_card_state(card)
    card.states.drag.can = Y
    card.states.collide.can = Y
    card.states.click.can = N
    if card._battle_drag_wrapped then return end

    local base_drag, base_stop_drag = card.drag, card.stop_drag
    card.drag = function(self, ctrl, offset)
        base_drag(self, ctrl, offset)
        local battle = self.gm and self.gm.run_loop and self.gm.run_loop.battle
        if battle and require("HMGplay.run_flow.game_run.battle").dismiss_dragged_card_if_far(battle, self, ctrl) then return end
        local mesh = self.children and self.children.mesh_card
        if mesh then mesh:hard_set_T(self.T.x, self.T.y, self.T.w, self.T.h) end
    end
    card.stop_drag = function(self)
        base_stop_drag(self)
        local zone = self.zone
        if zone and zone.align_cards then zone:align_cards() end
    end
    card._battle_drag_wrapped = Y
end

--- Helper: add to preview
local function _add_to_preview(zone, card)
    zone:add_card(card)
    _set_staged_card_state(card)
    zone:align_cards()
    card:sync_field_presentation()
end

--- Helper: stage highlighted
local function _stage_highlighted(battle)
    local hand = battle.gm.hand
    local selected = {}
    for _, card in ipairs(hand.highlighted or {}) do selected[#selected + 1] = card end
    if #selected == 0 then return end
    for _, card in ipairs(selected) do
        hand:remove_card(card)
        _add_to_preview(battle.pending_zone, card)
    end
end

--- Helper: restore card
local function _restore_card(entry)
    local card = entry.to:take_card(entry.card)
    if entry.from == entry.battle.gm.hand then
        State.restore_hand_card(entry.from, card)
    else
        _add_to_preview(entry.from, card)
    end
end

--- Helper: find placement
local function _find_placement(battle, card)
    for idx, entry in ipairs(battle.placements or {}) do
        if entry.card == card then return entry, idx end
    end
end

--- Helper: dismiss placement
local function _dismiss_placement(entry, idx)
    local battle, card = entry.battle, entry.card
    if card.zone and card.zone.take_card then card = card.zone:take_card(card) end
    table.remove(battle.placements, idx)
    if entry.from == battle.gm.hand then State.restore_hand_card(entry.from, card)
    else _add_to_preview(entry.from, card) end
end

--- Helper: point in rect
local function _point_in_rect(point, T) return point and T and point.x >= T.x and point.y >= T.y and point.x <= T.x + T.w and point.y <= T.y + T.h end

--- Helper: confirm placements
local function _confirm_placements(battle)
    if #battle.placements == 0 or #battle.pending_zone.cards > 0 then return end
    battle.busy, battle.turn = Y, "foe"
    local touched = {}
    for _, entry in ipairs(battle.placements) do
        entry.card.states.drag.can = N
        BattleLog.add_play(battle, "player", entry.column, entry.card)
        touched[entry.column] = Y
    end
    battle.placements = {}
    for column in pairs(touched) do Resolution.resolve_column(battle, column) end
    battle.gm.E_MANAGER:enqueue_event({
        trigger = "after",
        delay = 0.35,
        blockable = N,
        blocking = N,
        func = function() Turns.after_player_resolution(battle); return Y end,
    })
    return Y
end

--- Helper: queue auto confirm
local function _queue_auto_confirm(battle)
    if not battle.auto_confirm_placement or battle.auto_confirm_queued then return end
    if #battle.placements == 0 or #battle.pending_zone.cards > 0 then return end
    battle.auto_confirm_queued = Y
    battle.gm.E_MANAGER:enqueue_event({
        trigger = "after",
        delay = 0.10,
        blockable = N,
        blocking = N,
        func = function()
            battle.auto_confirm_queued = N
            if battle.active and battle.turn == "player" and not battle.busy and #battle.placements > 0 and #battle.pending_zone.cards == 0 then
                _confirm_placements(battle)
            end
            return Y
        end,
    })
end

function M.snap_dragged_card(battle, card)
    if not (battle and battle.active) or battle.busy or battle.turn ~= "player" then return end
    if not card then return end
    local entry = _find_placement(battle, card)
    if not (card.zone == battle.gm.hand or card.zone == battle.pending_zone or entry) then return end

    local point = battle.gm.CTRL and battle.gm.CTRL.cursor_hover and battle.gm.CTRL.cursor_hover.T
    for column, data in ipairs(battle.columns) do
        if _point_in_rect(point, data.drop_T) then return M.stage_card(battle, card, column) end
    end
end

-----------------------------
--- stage_card
----------------------------------
function M.stage_card(battle, card, column)
    if not (battle and battle.active) or battle.busy or battle.turn ~= "player" then return end
    local data = battle.columns[column]
    local zone = data and data.player.zone
    local from = card and card.zone
    if not zone or data.locked or #zone.cards >= zone.config.card_limit or not card or from == zone then return end
    local entry = _find_placement(battle, card)
    if not entry and #battle.placements >= 1 then return end
    if from ~= battle.gm.hand and from ~= battle.pending_zone and not entry then return end

    local moved = _remove_from_zone(card)
    if not moved then return end
    _add_to_preview(zone, card)
    if entry then
        entry.to, entry.column = zone, column
    else
        battle.placements[#battle.placements + 1] = { battle = battle, card = card, from = from, to = zone, column = column }
    end
    _queue_auto_confirm(battle)
    return Y
end

-----------------------------
--- dismiss_dragged_card_if_far
----------------------------------
function M.dismiss_dragged_card_if_far(battle, card, ctrl)
    if not (battle and battle.active) or battle.busy or battle.turn ~= "player" then return end
    local entry, idx = _find_placement(battle, card)
    if not entry then return end

    local zone = card.zone
    if not (zone and zone.config and zone.config.battle_side == "player") then return end
    local card_center = card.T.x + 0.5*card.T.w
    local zone_center = zone.T.x + 0.5*zone.T.w
    if math.abs(card_center - zone_center) <= 0.46*zone.T.w then return end

    _dismiss_placement(entry, idx)
    card.states.drag.is = N
    if ctrl and ctrl.dragging and ctrl.dragging.target == card then ctrl.dragging.target, ctrl.dragging.handled = nil, Y end
    if ctrl and ctrl.cursor_down and ctrl.cursor_down.target == card then ctrl.cursor_down.target, ctrl.cursor_down.handled = nil, Y end
    return Y
end

-----------------------------
--- undo
----------------------------------
function M.undo(battle)
    if not (battle and battle.active) or battle.busy or battle.turn ~= "player" then return end
    local entry = table.remove(battle.placements)
    if entry then _restore_card(entry); return Y end
    if #battle.pending_zone.cards == 0 then return end
    while battle.pending_zone.cards[1] do State.restore_hand_card(battle.gm.hand, battle.pending_zone:take_card(battle.pending_zone.cards[1])) end
    return Y
end

-----------------------------
--- play_or_confirm
----------------------------------
function M.play_or_confirm(battle)
    if not (battle and battle.active) or battle.busy or battle.turn ~= "player" then return end
    if #battle.placements > 0 then return _confirm_placements(battle) end
    return _stage_highlighted(battle)
end

return M
