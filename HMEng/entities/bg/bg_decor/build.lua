local TransAsset  = require("HMEng.entities.bg.bg_decor.data.asset_trans")
local MapSpawn    = require("HMfns.map.map_spawn")
local MathUtils   = require("HMfns.utils.math.math_utils")
local TableUtils  = require("HMfns.utils.table_utils")

local _pick         = TableUtils.random_pick
local _flip_sign, _unit    = MapSpawn.flip_sign, MapSpawn.unit
local abs,    lerp   = math.abs,   MathUtils.lerp
local max,    min    = math.max,   math.min
local floor,  rand   = math.floor, math.random

local Y, N = true, false

--- Helper: choose one asset key using per-asset spawn weights
local function _pick_asset_key(gm, cfg, keys, seed, cell_id) return MapSpawn.pick_weighted_key(gm, keys, TransAsset, seed, cell_id, 1) end

return function (BgDecor)
--------------------------------------------------
--- set atlas
--------------------------------------------------
function BgDecor:set_atlas(atlas_key)
    local gm,        atlas_key          = self.gm,                          atlas_key or self.atlas_key
    self.atlas,      self.atlas_key     = gm.T_atlas[atlas_key],            self.atlas_key
    self.atlas_dims, self.missing_keys  = self.atlas.image:getDimensions(), {}
    self:init_entries()
end

---------------------------------------------------
--- init_entries
---------------------------------------------------
--- Helper: resolve entry keys
local function _resolve_entry_keys(self)
    local cfg   = self.config or {}
    local keys  = cfg.entry_keys or {}
    if keys and keys[1] then return MapSpawn.filter_known_keys(keys, self.atlas) end
    return MapSpawn.sorted_keys(self.atlas.quads)
end

--- Helper: quad bounds
local function _quad_bounds(quad)
    local tl, tr, br, bl = quad[1], quad[2], quad[3], quad[4]; if not (tl and tr and br and bl) then return end
    return { min_x = min(tl.x, br.x), max_x = max(tr.x, br.x), min_y = tl.y, max_y = bl.y }
end

--- Helper: center-to-side throw prob
local function _cen2side_prob(cfg, c_idx, n_cols)
    local k       = cfg.cen2side_k or 1;            if k <= 0 or not c_idx or (n_cols or 0) <= 0 then return 0 end
    local center  = 0.5*((n_cols or 0) + 1)
    local dist    = abs(c_idx - center)
    return min(k/max(dist, 1), 1), dist
end

--- Helper: cen2side sign 
local function _cen2side_sign(gm, seed, cell_id, c_idx, n_cols)
    local center = 0.5*((n_cols or 0) + 1)
    if abs(c_idx - center) < 1e-6 then return _unit(gm, seed, cell_id, "side_sign") < 0.5 and -1 or 1 end
    return (c_idx < center and -1) or 1, center
end

--- Helper: build one cell-bound decor entry
local function _build_cell_entry(self, key, idx, seed, quad, cell_scale, c_idx, n_cols)
    local cfg,    T     = self.config or {}, self.T or {}
    local gm,    acfg   = self.gm, TransAsset[key] or {}
    local bounds        = _quad_bounds(quad);            if not bounds then return end

    local ux,    uy     = _unit(gm, seed, idx, "x"),     _unit(gm, seed, idx, "y")
    local us,    ur     = _unit(gm, seed, idx, "scale"), _unit(gm, seed, idx, "rot")

    local fp_x,  fp_y   = _flip_sign(gm, seed, idx, "flip_x", acfg.flip_x), _flip_sign(gm, seed, idx, "flip_y", acfg.flip_y)
    local r,     scale  = 2*acfg.r_max*(ur - 0.5), cfg.scale*cell_scale*lerp(us, acfg.s_max, acfg.s_min)
    local min_x, max_x  = bounds.min_x,            bounds.max_x
    local min_y, max_y  = bounds.min_y,            bounds.max_y

    local base_h,      base_w     = cfg.tile_h,                         cfg.tile_w
    local x,     y,    shader     = lerp(ux, max_x, min_x) - T.x,       lerp(uy, max_y, min_y) - T.y,  _pick(acfg.shader_set)
    local qw,    k,    bias_q     = max(max_x - min_x, 0),              cfg.throw_k,                   cfg.throw_bias_qs
    local throw_prob,  dist       = _cen2side_prob(cfg, c_idx, n_cols)
    local throw_roll,  group_idx  = _unit(gm, seed, idx, "cen2side"),   rand(1, max(cfg.num_groups or 1, 1))
    local dist_qw,     r_w        = dist*qw,                            n_cols*qw

    local _res = { key = key,      x = x,         y = y,       rot    = r,    sx = fp_x * scale,
        sy = fp_y * scale,   w = base_w,    h = base_h,  anchor = "top",
        shader = shader,      speed = acfg.speed,   group_idx = group_idx, sort_y = y }

    if throw_roll > throw_prob then return _res end

    local side_sign, center = _cen2side_sign(gm, seed, idx, c_idx, n_cols)
    x = x + side_sign*(bias_q*r_w - k*dist_qw)
    return _res
end

--- Helper: build entry from one grid cell
local function _build_gridzone_entry_at(self, keys, seed, r_idx, c_idx, group_idx, cell_tag)
    local gm,    cfg   = self.gm, self.config or {}
    local zone,  board = gm.gridzone, gm.field;                 if not zone or not r_idx or not c_idx then return end
    if board and board.cell_on_path and board:cell_on_path(r_idx, c_idx) then return end

    local metrics = zone:get_cell_metrics(r_idx, c_idx);        if not metrics or not metrics.quad then return end
    local cell_id = tostring(r_idx) .. ":" .. tostring(c_idx);  if cell_tag then cell_id = cell_id .. ":" .. tostring(cell_tag) end

    local key    = _pick_asset_key(gm, cfg, keys, seed, cell_id)
    local entry  = _build_cell_entry(self, key, cell_id, seed, metrics.quad, metrics.scale, c_idx, zone.n_cols or 0)
    if entry and group_idx ~= nil then entry.group_idx = group_idx end
    return entry
end

--- Helper: sort live entries by render y
local function _sort_entries(entries) table.sort(entries, function(a, b) return (a.sort_y or a.y or 0) < (b.sort_y or b.y or 0) end); return entries end

--- Helper: maybe build one gridzone entry for a cell
local function _maybe_build_gridzone_entry(self, keys, seed, chance, r_idx, c_idx)
    local gm       = self.gm
    local cell_id  = tostring(r_idx) .. ":" .. tostring(c_idx)
    if _unit(gm, seed, cell_id, "spawn") > chance then return end
    return _build_gridzone_entry_at(self, keys, seed, r_idx, c_idx)
end

--- Helper: build entries from non-path grid cells
local function _build_gridzone_entries(self, keys, seed)
    local gm,     cfg     = self.gm, self.config or {}
    local zone,   chance  = gm.gridzone, cfg.spawn_pr or 0.3
    local n_rows, n_cols  = zone and zone.n_rows or 0, zone and zone.n_cols or 0

    local entries = {}
    for r_idx = 1, n_rows do for c_idx = 1, n_cols do local entry = _maybe_build_gridzone_entry(self, keys, seed, chance, r_idx, c_idx); if entry then entries[#entries + 1] = entry end; end end
    return _sort_entries(entries)
end

---____________________________
--- main: init entries
---____________________________
function BgDecor:init_entries()
    local cfg = self.config or {}
    if cfg.entries and cfg.entries[1] then
        self.entries = cfg.entries
        for _, entry in ipairs(self.entries) do entry.group_idx = entry.group_idx or 1 end
        return self.entries
    end

    local gm, keys  = self.gm, _resolve_entry_keys(self)
    self.entries    = {};      if not keys[1] then return self.entries end

    self.entries = _build_gridzone_entries(self, keys, "bg_decor") or {}
    return self.entries
end

----------------------------------------
--- sort entries | resolve entry keys
----------------------------------------
function BgDecor:sort_entries()        self.entries = _sort_entries(self.entries or {}); return self.entries end
function BgDecor:resolve_entry_keys()  return _resolve_entry_keys(self) end

----------------------------------------
--- build gridzone entry at 
----------------------------------------
function BgDecor:build_gridzone_entry_at(keys, seed, r_idx, c_idx, group_idx, cell_tag)
    keys = keys or _resolve_entry_keys(self);        if not keys or not keys[1] then return end
    return _build_gridzone_entry_at(self, keys, seed or "bg_decor", r_idx, c_idx, group_idx, cell_tag)
end

----------------------------------------
--- build random gridzone entry 
----------------------------------------
function BgDecor:build_random_gridzone_entry(keys, seed, group_idx)
    local zone            = self.gm.gridzone;                     if not zone then return end 
    local n_rows, n_cols  = zone.n_rows or 0, zone.n_cols or 0;   if n_rows <= 0 or n_cols <= 0 then return end
    keys = keys or _resolve_entry_keys(self);                     if not keys or not keys[1] then return end

    local attempts  = max(n_rows*n_cols, 1)
    self.reborn_seq = (self.reborn_seq or 0) + 1

    for _ = 1, attempts do
        local r_idx, c_idx = rand(1, n_rows), rand(1, n_cols)
        local entry = _build_gridzone_entry_at(self, keys, seed or "bg_decor_reborn", r_idx, c_idx, group_idx, self.reborn_seq)
        if entry then return entry, r_idx, c_idx end
    end
end

end
