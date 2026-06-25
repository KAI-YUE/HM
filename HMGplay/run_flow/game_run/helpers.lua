local Ranks = require("HMGplay.cards.card_data.hand_ranks")

local Y, N = true, false

local M = {}

-----------------------------
--- graph movement
----------------------------------
local function _same_cell(a, b) return a and b and a.row == b.row and a.col == b.col end
local function _cell_key(cell) return tostring(cell.row) .. ":" .. tostring(cell.col) end

--- Helper: unique choices
local function _unique_choices(choices)
    local out, seen = {}, {}
    for _, cell in ipairs(choices or {}) do
        local key = _cell_key(cell)
        if not seen[key] then
            seen[key], out[#out + 1] = Y, cell
        end
    end
    return out
end

--- Helper: forward choices
local function _forward_choices(run, pawn, cell, previous_cell)
    local choices = _unique_choices(run.board and run.board:get_path_next_cells(cell.row, cell.col) or {})
    if #choices == 0 then return end

    if previous_cell then
        local filtered = {}
        for _, choice in ipairs(choices) do
            if not _same_cell(choice, previous_cell) then
                filtered[#filtered + 1] = choice
            end
        end
        choices = filtered
    end

    local valid = {}
    for _, choice in ipairs(choices) do
        if pawn:can_move_to_cell(choice.row, choice.col) then
            valid[#valid + 1] = choice
        end
    end
    return valid
end

--- Helper: automatic choice
local function _automatic_choice(run, pawn, choices)
    local choice = run.choose_path and run.choose_path(run, pawn, choices)
    if type(choice) == "number" then choice = choices[choice] end
    return choice or choices[1]
end

--- Helper: can complete steps
local function _can_complete_steps(run, pawn, current, previous, remaining)
    if remaining <= 0 then return Y end
    local choices = _forward_choices(run, pawn, current, previous) or {}
    for _, choice in ipairs(choices) do
        if _can_complete_steps(run, pawn, choice, current, remaining - 1) then return Y end
    end
    return N
end

--- Helper: route options
local function _route_options(run, pawn, steps)
    local start = pawn and pawn.cell or {}
    local result = { endpoints = {}, reachable = {} }
    local endpoint_seen = {}
    if not (run.board and start.row and start.col and steps > 0) then return result end

    local route = { { row = start.row, col = start.col } }
    local function walk(current, previous, remaining)
        if remaining <= 0 then
            local endpoint_key = _cell_key(current)
            for _, cell in ipairs(route) do result.reachable[_cell_key(cell)] = Y end
            if not endpoint_seen[endpoint_key] then
                endpoint_seen[endpoint_key] = Y
                result.endpoints[#result.endpoints + 1] = { row = current.row, col = current.col }
            end
            return
        end

        local choices = _unique_choices(run.board:get_path_next_cells(current.row, current.col))
        for _, target in ipairs(choices) do
            if not _same_cell(target, previous) and pawn:can_move_to_cell(target.row, target.col) then
                route[#route + 1] = { row = target.row, col = target.col }
                walk(target, current, remaining - 1)
                route[#route] = nil
            end
        end
    end

    walk(route[1], nil, math.floor(steps))
    if #result.endpoints == 0 then result.reachable[_cell_key(route[1])] = Y end
    return result
end

--- Helper: clear player move options
local function _clear_player_move_options(run)
    run.move_plan, run.move_plan_signature = nil, nil
    if run.board then run.board:clear_move_preview() end
end

--- Helper: card value
local function _card_value(card)
    local base = card and card.base or {}
    return tonumber(base.value) or tonumber(base.id) or tonumber(base.rank) or Ranks.values[tostring(base.rank)] or 0
end

--- Helper: refresh player move options
local function _refresh_player_move_options(run)
    local gm, pawn = run.gm, run.parties[1] and run.parties[1].pawn
    if run.battle and run.battle.active or run.busy or run.turn ~= 1 then
        run.move_plan, run.move_plan_signature = nil, nil
        if not run.pending_branch and run.board then run.board:clear_move_preview() end
        return
    end

    local card = gm.hand and gm.hand.highlighted[1]
    local cell, value = pawn and pawn.cell or {}, _card_value(card)
    local signature = table.concat({
        tostring(card and card.ID),
        tostring(value),
        tostring(run.board.route_version or 0),
        tostring(cell.row),
        tostring(cell.col),
    }, "|")
    if signature == run.move_plan_signature then return run.move_plan end

    run.move_plan_signature = signature
    if not card or value <= 0 then _clear_player_move_options(run); return end

    local plan = _route_options(run, pawn, value)
    plan.card, plan.value = card, value
    run.move_plan = plan
    run.board:set_move_preview({ active = Y, reachable = plan.reachable, dim_alpha = 0.24 })
    return plan
end

--- Helper: select player branch
local function _select_player_branch(run, cell)
    local pending = run.pending_branch
    local target = pending and pending.choices[_cell_key(cell)]
    if not target then return N end

    run.pending_branch = nil
    if run.board then run.board:clear_move_preview() end
    pending.resume(target)
    return Y
end

--- Helper: move pawn
local function _move_pawn(run, pawn, steps, on_done, interactive)
    if not (run.board and pawn) then
        if on_done then on_done() end
        return
    end

    local EM, moved, previous = run.gm.E_MANAGER, 0, nil
    local function finish_move()
        run.pending_branch = nil
        if run.board then run.board:clear_move_preview() end
        if on_done then on_done() end
        return Y
    end

    local function enqueue_next_step(step)
        EM:enqueue_event({
            trigger = "after",
            delay = 0.03,
            blockable = N,
            blocking = N,
            func = function()
                if pawn.toddle and pawn.toddle.active then return N end
                step()
                return Y
            end,
        })
    end

    local step
    local function move_to(target)
        local cell = pawn.cell or {}
        previous = { row = cell.row, col = cell.col }
        if not pawn:move_to_cell(target.row, target.col) then return finish_move() end
        moved = moved + 1
        enqueue_next_step(step)
        return Y
    end

    local function prompt_branch(choices)
        local choices_by_key, preview_cells = {}, {}
        for _, choice in ipairs(choices) do
            local key = _cell_key(choice)
            choices_by_key[key], preview_cells[key] = choice, choice
        end
        run.pending_branch = { pawn = pawn, choices = choices_by_key, resume = move_to }
        run.board:set_move_preview({
            active = Y,
            reachable = preview_cells,
            endpoints = preview_cells,
            dim_alpha = 0.24,
            choosing_branch = Y,
        })
        return Y
    end

    step = function()
        if moved >= steps then return finish_move() end
        local cell = pawn.cell or {}
        local choices = _forward_choices(run, pawn, cell, previous) or {}
        local valid = {}
        for _, choice in ipairs(choices) do
            if _can_complete_steps(run, pawn, choice, cell, steps - moved - 1) then
                valid[#valid + 1] = choice
            end
        end
        choices = valid
        if #choices == 0 then return finish_move() end
        if interactive and #choices > 1 then return prompt_branch(choices) end
        return move_to(_automatic_choice(run, pawn, choices))
    end

    step()
end

M.same_cell                   = _same_cell
M.cell_key                    = _cell_key
M.unique_choices              = _unique_choices
M.forward_choices             = _forward_choices
M.automatic_choice            = _automatic_choice
M.can_complete_steps          = _can_complete_steps
M.route_options               = _route_options
M.card_value                  = _card_value
M.clear_player_move_options   = _clear_player_move_options
M.refresh_player_move_options = _refresh_player_move_options
M.select_player_branch        = _select_player_branch
M.move_pawn                   = _move_pawn

return M
