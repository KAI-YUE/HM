local Fields   = require("HMGplay.cards.fields")
local Machi    = require("HMGplay.cards.card_data.machi")
local TabUtils = require("HMfns.utils.table_utils")

local random_pick = TabUtils.random_pick
local deep_copy   = TabUtils.deep_copy

local Y = true

local M = {}

--------------------------------------------------
--- reveal a hidden field cell
--------------------------------------------------
--- Helper: _machi_keys
local function _machi_keys()
    local keys = {}
    for key in pairs(Machi) do keys[#keys + 1] = key end
    return keys
end

--- Helper: _ensure_field_card
local function _ensure_field_card(gm, row, col, opts)
    local cells  = gm.gridzone.cells[row]
    local card   = cells and cells[col]
    
    if card then if opts and opts.card then card:set_base(deep_copy(opts.card), Y) end; return card; end

    opts = opts or {}
    if opts.card then
        Fields.spawn_card2field(gm, { card = deep_copy(opts.card), r_idx = row, c_idx = col, facing = opts.facing or "front" })
        return cells and cells[col]
    end

    Fields.spawn_special_card2field(gm, opts.card_set or "machi", opts.card_key or random_pick(_machi_keys()), {
        r_idx = row, c_idx = col, facing = opts.facing or "front",
    })
    return cells and cells[col]
end

---______________________________________________
--- Main: reveal a hidden field cell
---_______________________________________________
function M.reveal_hidden_cell(gm, row, col, opts)
    if not (gm.field and gm.gridzone and row and col) then return end
    local card = _ensure_field_card(gm, row, col, opts);                if not card then return end

    local key = tostring(row) .. ":" .. tostring(col)
    if not gm.field:get_path_for_cell(row, col) then gm.field.revealed_field_cells[key] = { row = row, col = col } end
    
    gm.field:append_revealed_route_cell(row, col)
    if card.states then card.states.visible = Y end
    
    gm.gridzone:align_card_at(row, col)
    return card, Y
end

return M
