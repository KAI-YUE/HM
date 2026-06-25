local Fields   = require("HMGplay.cards.fields")
local TabUtils = require("HMfns.utils.table_utils")
local Machi    = require("HMGplay.cards.card_data.machi")

local spawn_card2deck           = Fields.spawn_card2deck
local spawn_card2field          = Fields.spawn_card2field
local spawn_special_card2deck   = Fields.spawn_special_card2deck
local spawn_special_card2field  = Fields.spawn_special_card2field

local rand_pick = TabUtils.random_pick
local max = math.max

local Y, N = true, false

local Fsuits = { "F", "W", "E", "M", "R", "H", "D", "S", "C", "SM"  }
local Rsuits = {  "F", "W", "M" }
-- local Rsuits = { "SM" }
local Tvals  = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }
local Tranks = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "V", "X" }
-- local Tranks = { "1", }

--- key list 
local function keys_list(t) local out = {}; for k, _ in pairs(t) do out[#out + 1] = k end; return out end

-------------------------------------------------
--- Helper: field card spawning
-------------------------------------------------
local function field_cell_for_counter(counter, n_cols) return math.floor((counter-1)/n_cols) + 1, ((counter-1)%n_cols) + 1 end

local function field_counter_for_cell(r_idx, c_idx, n_cols)
    if not r_idx or not c_idx or not n_cols then return end
    return (r_idx - 1)*n_cols + c_idx
end

local function spawn_machi_field_card(gm, keys, r_idx, c_idx)
    local _card_name = rand_pick(keys)
    spawn_special_card2field(gm, "machi", _card_name, { r_idx = r_idx, c_idx = c_idx, facing = "front" })
    local row = gm.gridzone and gm.gridzone.cells and gm.gridzone.cells[r_idx]
    local card = row and row[c_idx]
    if card and card.states and gm.field and not gm.field:cell_on_path(r_idx, c_idx) then card.states.visible = N end
    return card
end

local M = {}
------------------------------------------
--- init gameplay params 
------------------------------------------
function M.init_gameplay_params() return { money = 4, hp = 100, full = 100, hand_size = 10 } end

------------------------------------------
--- init deck 
------------------------------------------
function M.init_deck(gm, args)
    for i, suit in ipairs(Rsuits) do
        for _, rank in ipairs(Tranks) do spawn_card2deck(gm, { s = suit, r = rank, facing = "back" }) end
    end

    -- spawn_special_card2deck(gm, "meshi", "egg")
    -- spawn_special_card2deck(gm, "meshi", "egg2")
end

------------------------------------------
--- init field
------------------------------------------
function M.init_field_(gm, args)
    local Fcfg = gm.Fcfg
    local counter, n_rows, n_cols = 0, Fcfg.n_rows, Fcfg.n_cols
    for i, suit in ipairs(Fsuits) do 
        for rank, values in ipairs(Tvals) do
            local r_idx, c_idx = math.floor(counter/n_cols) + 1, (counter) % n_cols + 1 
            counter = counter + 1
            if r_idx > n_rows then return end 
            spawn_card2field(gm, { s = suit, r = values, r_idx = r_idx, c_idx = c_idx })
        end
    end
end

function M.init_field(gm, args)
    local Fcfg = gm.Fcfg
    local counter, n_rows, n_cols = 0, Fcfg.n_rows, Fcfg.n_cols
    local Machi_keys = keys_list(Machi)

    local num_cells = n_rows*n_cols
    for counter = 1, num_cells do
        local r_idx, c_idx = field_cell_for_counter(counter, n_cols)
        if r_idx > n_rows then return end 
        spawn_machi_field_card(gm, Machi_keys, r_idx, c_idx)
    end
end

-------------------------------------------------
--- init field progressively
-------------------------------------------------
function M.init_field_progressive(gm, args)
    args = args or {}
    local Fcfg, EM = gm.Fcfg, gm.E_MANAGER
    if not EM then return M.init_field(gm, args) end

    local n_rows, n_cols = Fcfg.n_rows, Fcfg.n_cols
    local num_cells = n_rows*n_cols
    local batch_size = max(1, args.batch_size or 8)
    local batch_delay = args.batch_delay or (1/60)
    local Machi_keys = keys_list(Machi)
    local spawned, counter = {}, 1
    local hide_until_reveal = args.hide_until_reveal ~= N

    local function spawn_counter(idx)
        if idx < 1 or idx > num_cells or spawned[idx] then return end
        local r_idx, c_idx = field_cell_for_counter(idx, n_cols)
        if r_idx > n_rows then return end
        spawned[idx] = Y
        local card = spawn_machi_field_card(gm, Machi_keys, r_idx, c_idx)
        if hide_until_reveal and card and card.states then card.states.visible = N end
    end

    for _, path in ipairs(gm.field and gm.field.paths or {}) do
        local start_cell = path.start_cell
        local start_idx = field_counter_for_cell(start_cell and start_cell.row, start_cell and start_cell.col, n_cols)
        if start_idx then spawn_counter(start_idx) end
    end

    local function spawn_batch()
        local spawned_in_batch = 0
        while counter <= num_cells and spawned_in_batch < batch_size do
            spawn_counter(counter)
            counter = counter + 1
            spawned_in_batch = spawned_in_batch + 1
        end

        while counter <= num_cells and spawned[counter] do counter = counter + 1 end
        if counter <= num_cells then
            EM:enqueue_event({ trigger = "after", delay = batch_delay, blockable = N, blocking = N, func = spawn_batch })
        elseif args.on_done then
            args.on_done(gm)
        end
        return Y
    end

    return spawn_batch()
end

return M
