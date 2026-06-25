local RunLog   = require("HMGplay.run_flow.log")
local LogPanel = require("HMGplay.run_flow.log_panel")

local M = {}

-----------------------------
--- new
----------------------------------
--- Helper: card label
local function _card_label(card)
    local base = card and card.base or {}
    local rank = base.rank_label or base.rank or base.value or (card and card.battle_foe_value) or "?"
    local suit = base.suit or "?"
    return tostring(rank) .. tostring(suit)
end

--- Helper: format entry
local function _format_entry(entry)
    local payload = entry.payload or {}
    return tostring(entry.actor) .. " -> C" .. tostring(payload.column) .. " : " .. tostring(payload.card)
end

function M.new()
    return RunLog.new({
        title       = "Battle Log",
        empty_text  = "No cards played yet.",
        max_visible = 8,
        formatter   = _format_entry,
    })
end

-----------------------------
--- add_play
----------------------------------
--- Helper: refresh panel
local function _refresh_panel(battle) LogPanel.refresh(battle.log_panel) end

function M.add_play(battle, actor, column, card)
    battle.log = battle.log or M.new()
    RunLog.add(battle.log, {
        scope   = "battle",
        kind    = "card_played",
        actor   = actor == "foe" and "FOE" or "Player",
        payload = {
            column = column,
            card   = _card_label(card),
            base   = card and card.base,
        },
    })
    _refresh_panel(battle)
end

-----------------------------
--- toggle_panel
----------------------------------
function M.toggle_panel(battle)
    battle.log_open = not battle.log_open
    LogPanel.set_visible(battle.log_panel, battle.log_open)
    _refresh_panel(battle)
    return true
end

-----------------------------
--- refresh_panel
----------------------------------
function M.refresh_panel(battle) _refresh_panel(battle) end

return M
