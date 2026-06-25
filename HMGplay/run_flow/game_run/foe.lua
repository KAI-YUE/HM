local TabUtils = require("HMfns.utils.table_utils")
local Helpers  = require("HMGplay.run_flow.game_run.helpers")

local shuffle = TabUtils.shuffle_in_place

local Y, N = true, false

local M = {}

-----------------------------
--- new_foe_deck
----------------------------------
--- Helper: new foe deck
local function _new_foe_deck()
    local deck = {}
    for _ = 1, 3 do
        for value = 1, 10 do
            deck[#deck + 1] = value
        end
    end
    shuffle(deck)
    return deck
end

--- Helper: draw foe
local function _draw_foe(run)
    local foe = run.parties[2]
    if not foe then return end
    while #foe.hand < run.foe_hand_size and #foe.deck > 0 do
        foe.hand[#foe.hand + 1] = table.remove(foe.deck)
    end
end

-----------------------------
--- refresh_foe_preview
----------------------------------
--- Helper: preview pawn route
local function _preview_pawn_route(run, pawn, steps)
    local board, cell = run.board, pawn and pawn.cell or {}
    local route = {}
    if not (board and cell.row and cell.col) then return route end

    local row, col, previous = cell.row, cell.col, nil
    route[1] = { row = row, col = col }
    for _ = 1, math.max(0, math.floor(steps or 0)) do
        local choices = Helpers.unique_choices(board:get_path_next_cells(row, col))
        if previous and #choices > 1 then
            local filtered = {}
            for _, choice in ipairs(choices) do
                if not Helpers.same_cell(choice, previous) then
                    filtered[#filtered + 1] = choice
                end
            end
            if #filtered > 0 then choices = filtered end
        end
        local target = choices and choices[1]
        if not target then break end
        previous, row, col = { row = row, col = col }, target.row, target.col
        route[#route + 1] = { row = row, col = col }
    end
    return route
end

--- Helper: refresh foe preview
local function _refresh_foe_preview(run)
    if run.battle and run.battle.active then
        if run.foe_preview then run.foe_preview.states.visible = N end
        return
    end
    local foe = run.parties[2]
    local value = foe and foe.hand and foe.hand[1] or 0
    if not run.foe_preview then return end
    run.foe_preview:set_preview(run.board, _preview_pawn_route(run, foe and foe.pawn, value), value)
end

-----------------------------
--- play_foe_turn
----------------------------------
--- Helper: play foe turn
local function _play_foe_turn(run)
    run.turn = 2
    Helpers.clear_player_move_options(run)
    if run.foe_preview then run.foe_preview.states.visible = N end
    _draw_foe(run)
    local foe = run.parties[2]
    local value = foe and table.remove(foe.hand, 1) or 0
    if value <= 0 then return end
    foe.discard[#foe.discard + 1] = value
    Helpers.move_pawn(run, foe.pawn, value, function()
        _draw_foe(run)
        if run.on_begin_player_turn then run.on_begin_player_turn(run) end
    end)
end

M.new_foe_deck = _new_foe_deck
M.draw_foe     = _draw_foe
M.refresh_foe_preview = _refresh_foe_preview
M.play_foe_turn      = _play_foe_turn

return M
