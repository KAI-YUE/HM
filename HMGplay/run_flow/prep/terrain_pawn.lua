local TerrainPawn = require("HMEng.entities.pawn.terrain_pawn")
local Tterrain    = require("HMEng.entities.pawn.terrain_pawn.data.terrain_trans")
local MathUtils   = require("HMfns.utils.math.math_utils")
local MapSpawn    = require("HMfns.map.map_spawn")

local unit  = MapSpawn.unit
local _lerp = MathUtils.lerp

local Y, N = true, false
local Tcfg_param_keys   = { "atlas_key", "can_drag", "can_hover", "can_click", "static" }
local Ttrans_param_keys = { "foot_x", "shader" }
local Tanim_param_keys  = { "can_drag", "can_hover", "can_click", "static", "model_key", "model_def", "fit_axis", "anim_gust", "vivid_color", "shadow_color" }

-----------------------------
--- spawn_on_field
----------------------------------
--- Helper: copy keys | pick sprite key | resolve flip
local function _copy_keys(dst, src, keys)                     for _, key in ipairs(keys) do local val = src and src[key]; if val ~= nil then dst[key] = val end end; return dst end
local function _pick_sprite_key(gm, cfg, keys, seed, cell_id) return MapSpawn.pick_weighted_key(gm, keys, cfg.sprite_trans or Tterrain, seed, cell_id, 1) end
local function _resolve_flip(gm, seed, cell_id, tag, enabled) if not enabled then return 1 end; return MapSpawn.flip_sign(gm, seed, cell_id, tag, enabled) end

--- Helper: anim pawn class
local AnimTerrainPawn
local function _anim_pawn_class()
    AnimTerrainPawn = AnimTerrainPawn or require("HMEng.entities.pawn.anim_terrain_pawn")
    return AnimTerrainPawn
end

local M = {}

--- Helper: resolve sprite keys
local function _resolve_sprite_keys(gm, cfg)
    local TA = gm.T_atlas or {}
    local atlas = (cfg.atlas_key and TA[cfg.atlas_key]) or TA.pawns
    if not atlas then return nil, {} end

    if cfg.sprite_keys and cfg.sprite_keys[1] then return atlas, MapSpawn.filter_known_keys(cfg.sprite_keys, atlas) end
    if cfg.sprite_name and atlas.quads and atlas.quads[cfg.sprite_name] then return atlas, { cfg.sprite_name } end
    return atlas, MapSpawn.sorted_keys(atlas.quads)
end

--- Helper: cell open
local function _cell_vacant(zone, r_idx, c_idx)  local row = zone and zone.pawns and zone.pawns[r_idx]; return (not row) or #(row[c_idx] or {}) == 0 end
local function _cell_open(zone, r_idx, c_idx)
    return _cell_vacant(zone, r_idx - 1, c_idx)
       and _cell_vacant(zone, r_idx,     c_idx)
       and _cell_vacant(zone, r_idx + 1, c_idx)
end
local function _cell_valid_empty(zone, r_idx, c_idx)
    local row   = zone and zone.pawns and zone.pawns[r_idx]
    local cells = zone and zone.cells and zone.cells[r_idx]
    return row and cells and cells[c_idx] and #(row[c_idx] or {}) == 0
end

--- Helper: pawn dims
local function _pawn_dims(atlas, sprite_name, height)
    local quad = atlas and atlas.get_quad and atlas:get_quad(sprite_name)
    if not quad then return 2 * height, height end

    local _, _, qw, qh = quad:getViewport()
    local ratio = (qh > 0) and (qw / qh) or 2
    return height * ratio, height
end

--- Helper: spawn one anim
local function _spawn_one_anim(gm, board, zone, cfg, seed, r_idx, c_idx, forced)
    if not (board and zone) then return end
    if forced then
        if not _cell_valid_empty(zone, r_idx, c_idx) then return end
    else
        if board.cell_on_path and not cfg.allow_path and board:cell_on_path(r_idx, c_idx) then return end
        if not _cell_open(zone, r_idx, c_idx) then return end
    end

    local cell_id = tostring(r_idx) .. ":" .. tostring(c_idx)
    if not forced and unit(gm, seed, cell_id, "spawn") > (cfg.spawn_pr or 0.08) then return end

    local size_u = (cfg.scale or 1) * _lerp(unit(gm, seed, cell_id, "scale"), cfg.s_max or 1, cfg.s_min or 1)
    local ph     = cfg.anim_h or cfg.tile_h * size_u
    local pw     = cfg.anim_w or (cfg.tile_w or cfg.tile_h) * size_u

    local init_cfg = { zone = zone, parent = board or zone, row = r_idx, col = c_idx, visible = (cfg.visible ~= N), }
    local params = _copy_keys(init_cfg, cfg, Tanim_param_keys)
    params.template_shader, params.spawn_seed, params.cell_id = cfg.template_shader or "plain", seed, cell_id
    params.flip_x = _resolve_flip(gm, seed, cell_id, "flip_x", cfg.flip_x)
    params.flip_y = _resolve_flip(gm, seed, cell_id, "flip_y", cfg.flip_y)

    local pawn = _anim_pawn_class()(gm, 0, 0, pw, ph, params)
    board:emplace_pawn(pawn, r_idx, c_idx)
    return pawn
end

--- Helper: debug anim spawn
local function _debug_anim_spawn(gm, board, zone, cfg, seed)
    local dbg = cfg.anim_debug_spawn
    if not (dbg and dbg.enabled == Y) then return end
    local r_idx, c_idx = dbg.row or dbg.r or 1, dbg.col or dbg.c or 1
    return _spawn_one_anim(gm, board, zone, cfg, dbg.seed or seed or "anim_terrain_debug", r_idx, c_idx, Y)
end

--- Helper: spawn one
local function _spawn_one(gm, board, zone, atlas, cfg, seed, keys, r_idx, c_idx)
    if board and board.cell_on_path and not cfg.allow_path and board:cell_on_path(r_idx, c_idx) then return end
    if not _cell_open(zone, r_idx, c_idx) then return end

    local cell_id = tostring(r_idx) .. ":" .. tostring(c_idx)
    if unit(gm, seed, cell_id, "spawn") > (cfg.spawn_pr or 0.08) then return end

    local sprite_name  = _pick_sprite_key(gm, cfg, keys, seed, cell_id); if not sprite_name then return end
    local trans        = (cfg.sprite_trans or Tterrain)[sprite_name] or {}
    local size_u       = (cfg.scale or 0.65) * _lerp(unit(gm, seed, cell_id, "scale"), trans.s_max or 1, trans.s_min or 1)
    local ph           = cfg.tile_h * size_u
    local pw           = _pawn_dims(atlas, sprite_name, ph)

    local init_cfg = { zone = zone, parent = board or zone, row = r_idx, col = c_idx, sprite_name = sprite_name, visible = (cfg.visible ~= N), }
    local params   = _copy_keys(init_cfg, cfg, Tcfg_param_keys)
    _copy_keys(params, trans, Ttrans_param_keys)

    local f_x = _resolve_flip(gm, seed, cell_id, "flip_x", trans.flip_x or cfg.flip_x)
    local f_y = _resolve_flip(gm, seed, cell_id, "flip_y", trans.flip_y or cfg.flip_y)

    params.flip_x,          params.flip_y     = f_x, f_y
    params.template_shader, params.spawn_seed = params.shader or cfg.template_shader, seed
    params.cell_id = cell_id

    local pawn = TerrainPawn(gm, 0, 0, pw, ph, params)

    board:emplace_pawn(pawn, r_idx, c_idx)
    return pawn
end

function M.spawn_on_field(gm, config)
    local cfg,   spawned  = config or {}, {}
    local board, zone     = cfg.board or gm.field, cfg.zone or gm.gridzone
    local seed            = cfg.seed or "terrain_pawn"

    local debug_pawn = _debug_anim_spawn(gm, board, zone, cfg, seed)
    if debug_pawn then spawned[#spawned + 1] = debug_pawn; return spawned end

    if cfg.anim == Y then
        if not zone then return spawned end
        for r_idx = 1, zone.n_rows do for c_idx = 1, zone.n_cols do local pawn = _spawn_one_anim(gm, board, zone, cfg, seed, r_idx, c_idx); if pawn then spawned[#spawned + 1] = pawn end end end
        return spawned
    end

    local atlas, keys     = _resolve_sprite_keys(gm, cfg)

    if not zone or not atlas or not keys[1] then return spawned end
    for r_idx = 1, zone.n_rows do for c_idx = 1, zone.n_cols do local pawn = _spawn_one(gm, board, zone, atlas, cfg, seed, keys, r_idx, c_idx); if pawn then spawned[#spawned + 1] = pawn end end end

    return spawned
end

return M
