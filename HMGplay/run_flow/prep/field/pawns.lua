local Pawn = require("HMEng.entities.pawn")

local Y, N = true, false

local M = {}

-----------------------------
--- place_pawns
----------------------------------
--- Helper: get path start
local function _get_path_start(field, party_idx)
    local path = field.paths and field.paths[party_idx] or field.path or {}
    return path.start_cell
end

--- Helper: saved field pawn
local function saved_field_pawn(opts)
    local pawns = opts and opts.world and opts.world.pawns and opts.world.pawns.pawns
    if type(pawns) ~= "table" then return end
    for _, pawn in ipairs(pawns) do if pawn.zone_type == "field" or pawn.kind == "pawn" then return pawn end end
end

--- Helper: saved pawn cell
local function saved_pawn_cell(field, snap, party_idx)
    local cell = snap and snap.cell
    if cell and cell.row and cell.col then return cell.row, cell.col end
    local start = _get_path_start(field, party_idx) or {}
    return start.row or 1, start.col or 1
end

--- Helper: place one party pawn
local function _place_party_pawn(gm, field, opts, party_idx, snap)
    local row, col = saved_pawn_cell(field, snap, party_idx)
    local foe      = party_idx > 1
    local ps       = foe and 0.58 or 0.65
    local pawn     = Pawn(gm, 0, 0, ps*field.cell_w, ps*field.cell_h, {
        static = snap and snap.static,
        visual_tint = foe and { 0.95, 0.42, 0.38, 1 } or nil,
    })
    local sprite   = "barricade"

    pawn.party_idx = party_idx
    pawn:assign_visual((snap and snap.sprite_key) or sprite, (snap and snap.atlas_key) or "pawns")
    pawn.states.visible = opts and opts.silent_start and Y or ((snap and snap.visible) or N)
    field:emplace_pawn(pawn, row, col)
    return pawn
end

function M.place_pawns(gm, opts)
    local field = gm.field;         if not field then return end
    local count = math.max(1, (gm.run_loop and gm.run_loop.party_count) or 1)
    local snap  = saved_field_pawn(opts)

    gm.party_pawns = {}
    for i = 1, count do gm.party_pawns[i] = _place_party_pawn(gm, field, opts, i, i == 1 and snap or nil) end
    gm.field_pawn, gm.foe_pawn = gm.party_pawns[1], gm.party_pawns[2]
end

function M.place_pawn(gm, opts) return M.place_pawns(gm, opts) end

return M
