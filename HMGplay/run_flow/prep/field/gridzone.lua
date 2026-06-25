local BoardZone   = require("HMEng.entities.board.boardzone")
local GridZone    = require("HMEng.entities.board.gridzone")
local FieldRise   = require("HMfns.animate.start.field_cards")
local TerrainPrep = require("HMGplay.run_flow.prep.terrain_pawn")
local BoardReveal = require("HMGplay.board.reveal")
local Pawns       = require("HMGplay.run_flow.prep.field.pawns")

local max = math.max

local Y = true

local M = {}

-----------------------------
--- init_terrain_pawn
----------------------------------
function M.init_terrain_pawn(gm)
    local cfg = gm.TPcfg or {}
    gm.terrain_pawns = TerrainPrep.spawn_on_field(gm, cfg)
    return gm.terrain_pawns
end

-----------------------------
--- init_gridzone
----------------------------------
--- Helper: restore revealed field cells
local function _restore_revealed_field_cells(gm, opts)
    local field = opts and opts.world and opts.world.field
    for _, cell in ipairs(field and field.revealed_cells or {}) do
        BoardReveal.reveal_hidden_cell(gm, cell.row, cell.col, { card = cell.card, facing = "front" })
    end
end

--- Helper: compute field rect
local function _compute_field_rect(gm)
    local Fcfg, room       = gm.Fcfg or {}, gm._room
    local RT               = room and room.T
    local n_rows, n_cols   = Fcfg.n_rows or 1, Fcfg.n_cols or 1
    local card_w, card_h   = gm.card_w or 1,   gm.card_h or 1

    local board_w, board_h = n_cols*card_w, n_rows*card_h
    if not RT or board_w  <= 0 or board_h <= 0 then return { x = 0, y = 0, w = board_w, h = board_h } end

    local fit_w, fit_h     = (Fcfg.scale_x or 1)*RT.w, (Fcfg.scale_y or 1)*RT.h
    local board_aspect     = board_w / board_h
    local fit_aspect       = fit_w / max(fit_h, 1e-6)
    local field_w, field_h = 0, 0

    if board_aspect >= fit_aspect then field_w, field_h = fit_w, fit_w / max(board_aspect, 1e-6)
    else                               field_h, field_w = fit_h, fit_h * board_aspect end

    return { x = 0, y = 0, w = field_w, h = field_h }
end

function M.init_gridzone(gm, opts)
    opts = opts or {}
    local Fs, Fcfg        = gm.Fs, gm.Fcfg
    local field_rect      = _compute_field_rect(gm)

    gm.field = BoardZone(gm, field_rect.x, field_rect.y, field_rect.w, field_rect.h, { type = "field_board",
        path = { kind = "rectangle", inset = 2, component_gap = 2,
            mutation = { enabled = Y, max_edges = 3, corner_margin = 3 } },
    })

    local _r, _c   = Fcfg.n_rows, Fcfg.n_cols

    local gridzone = GridZone(gm, field_rect.x, field_rect.y, field_rect.w, field_rect.h, {
        n_rows = _r, n_cols = _c, type = "field", projector = Fcfg.proj,
        cell_variance = {    enabled = Y,       seed   = "field_loose_align",
            row_x  = 0.005,   row_y  = 0.002,   row_r  = 0.002,
            col_x  = 0.00,    col_y  = 0.005,   col_r  = 0.00,
            cell_x = 0.005,   cell_y = 0.005,   cell_r = 0.002,
        },
    })

    gm.field:set_gridzone(gridzone)
    local path_kind = gm.field.config and gm.field.config.path and gm.field.config.path.kind
    local paths = path_kind == "graph" and gm.field.paths or gm.field:split_path_components((gm.run_loop and gm.run_loop.party_count) or 1)
    if gm.run_loop then gm.run_loop.party_count = #paths end
    if gm.bg_decor then gm.field:set_bg_decor(gm.bg_decor) end
    gm.gridzone = gridzone
    gridzone.states.collide.can, gridzone.states.hover.can = Y, Y
    if opts.field_spawn_batch_size and Fs.init_field_progressive then
        Fs.init_field_progressive(gm, { batch_size = opts.field_spawn_batch_size, batch_delay = opts.field_spawn_batch_delay,
            hide_until_reveal = opts.field_spawn_hide_until_reveal,
            on_done = function()
                _restore_revealed_field_cells(gm, opts)
                if not opts.silent_start then FieldRise.animate_field_cards_rise(gm) end
                if opts.on_prepared then opts.on_prepared(gm) end
            end })
    else
        Fs.init_field(gm)
        _restore_revealed_field_cells(gm, opts)
        if opts.field_spawn_batch_size and opts.on_prepared then opts.on_prepared(gm) end
    end
    M.init_terrain_pawn(gm)

    Pawns.place_pawns(gm, opts)
    if not opts.silent_start and not opts.field_spawn_batch_size then FieldRise.animate_field_cards_rise(gm) end
end

return M
