local TabUtils = require("HMfns.utils.table_utils")

local _pick    = TabUtils.random_pick
local ceil, min, max = math.ceil, math.min, math.max
local pi = math.pi

local Ttile  = { "01", "02", "03", "04" }
local Tlight = { 0.25, 0.15, 0.65, 0.25 }
local Ttile  = { "03",  }
local Tlight = { 0.65,  }

local Trot   = { 0, 0.5*pi, pi, 1.5*pi }
local Tflip  = { -1, 1 }

local Y, N = true, false

return function (TiledMap)
--------------------------------------------------
--- mark tile dirty
--------------------------------------------------
--- Helper: get chunk coords
function TiledMap:get_chunk_coords(r_idx, c_idx) local cfg = self.config; return ceil(r_idx / cfg.chunk_rows), ceil(c_idx / cfg.chunk_cols) end

--- Helper: mark chunk dirty
function TiledMap:mark_chunk_dirty(chunk_r, chunk_c)
    local row    = self.chunks and self.chunks[chunk_r]
    local chunk  = row and row[chunk_c]
    if chunk then chunk.dirty = Y end
end

---________________________________
--- main: mark tile dirty 
---________________________________
function TiledMap:mark_tile_dirty(r_idx, c_idx) local chunk_r, chunk_c = self:get_chunk_coords(r_idx, c_idx); self:mark_chunk_dirty(chunk_r, chunk_c) end
function TiledMap:mark_all_chunks_dirty()       for _, row in ipairs(self.chunks or {}) do for _, chunk in ipairs(row) do chunk.dirty = Y end end; end

--------------------------------------------------
--- set atlas
--------------------------------------------------
function TiledMap:set_atlas(atlas_key)
    self.atlas_key   = atlas_key or self.atlas_key
    self.atlas       = (self.gm.T_atlas or {})[self.atlas_key]
    self.atlas_dims  = {}
    if self.atlas and self.atlas.image then self.atlas_dims[1], self.atlas_dims[2] = self.atlas.image:getDimensions() end
    self.missing_keys = {}
    self:mark_all_chunks_dirty()
end

--------------------------------------------------
--- settle random tiles
--------------------------------------------------
--- Helper: choose tile entry once
function TiledMap:init_tile_entry()
    local cfg = self.config or {};      if cfg.random_tiles then return end

    local tile, idx  = _pick(Ttile)
    self.tile_key    = tile
    self.tile_light  = Tlight[idx]
end

--- Helper: get tile entry
local function _get_tile_entry(self)
    local cfg = self.config or {}
    if not cfg.random_tiles then return self.tile_key, self.tile_light; end

    local _, key = _pick((self.atlas and self.atlas.quads) or {})
    return key
end

--- Helper: make tile variant
local function _randomize_tile(tile, light_boost)
    if not tile then return end
    local out = { key = tile, rot = _pick(Trot), sx = _pick(Tflip), sy = _pick(Tflip) }
    if light_boost ~= nil then out.shader_opts = { send = { { name = "LightBoost", val = light_boost } } }; end
    return out
end

--- Helper: _next_random_tile
local function _next_random_tile(self)
    local tile, light_boost = _get_tile_entry(self)
    return _randomize_tile(tile, light_boost)
end

---________________________________
--- main: settle random tiles
---________________________________
function TiledMap:settle_random_tiles(r1, c1, r2, c2)
    r1, c1 = r1 or 1, c1 or 1
    r2, c2 = r2 or self.n_rows, c2 or self.n_cols

    for r = r1, r2 do
        local row = self.tiles[r];
        if row then for c = c1, c2 do row[c] = _next_random_tile(self) end end
    end
    self:mark_all_chunks_dirty()
end

--------------------------------------------------
--- get | set tiles
--------------------------------------------------
function TiledMap:get_tile(r_idx, c_idx) local row = self.tiles and self.tiles[r_idx]; return row and row[c_idx]  end
function TiledMap:set_tile(r_idx, c_idx, tile)
    local row = self.tiles and self.tiles[r_idx]
    if not row or c_idx < 1 or c_idx > self.n_cols then return end
    row[c_idx] = tile
    self:mark_tile_dirty(r_idx, c_idx)
end

---------------------------------------------
--- fill 
---------------------------------------------
function TiledMap:fill(tile, r1, c1, r2, c2)
    r1, c1 = r1 or 1, c1 or 1
    r2, c2 = r2 or self.n_rows, c2 or self.n_cols

    for r = r1, r2 do
        local row = self.tiles[r]
        if row then for c = c1, c2 do row[c] = tile end end
    end
    self:mark_all_chunks_dirty()
end

-------------------------------------------
--- size 
-------------------------------------------
--- Helper: build chunk
local function _build_chunk(cfg, n_rows, n_cols, chunk_r, chunk_c)
    local r1, r2 = (chunk_r - 1)*cfg.chunk_rows + 1, min(chunk_r*cfg.chunk_rows, n_rows)
    local c1, c2 = (chunk_c - 1)*cfg.chunk_cols + 1, min(chunk_c*cfg.chunk_cols, n_cols)
    return { row = chunk_r,  col = chunk_c,  dirty = Y,  r1 = r1, r2 = r2, c1 = c1, c2 = c2 }
end

--- Helper: rebuild chunks 
local function _rebuild_chunks(self)
    local cfg = self.config
    local n_chunk_rows, n_chunk_cols = ceil(self.n_rows/cfg.chunk_rows), ceil(self.n_cols/cfg.chunk_cols)

    self.chunks = {}
    for chunk_r = 1, n_chunk_rows do
        local row = {}
        self.chunks[chunk_r] = row
        for chunk_c = 1, n_chunk_cols do row[chunk_c] = _build_chunk(cfg, self.n_rows, self.n_cols, chunk_r, chunk_c) end
    end
end

---_______________________________
--- main: resize 
---_______________________________
function TiledMap:resize(n_rows, n_cols, fill)
    n_rows, n_cols = max(1, n_rows or self.n_rows), max(1, n_cols or self.n_cols)

    local prev = self.tiles or {}
    self.n_rows, self.n_cols = n_rows, n_cols
    self.tiles = {}

    for r = 1, n_rows do
        local row = {};       self.tiles[r] = row
        for c = 1, n_cols do
            local prev_row = prev[r]
            row[c] = (prev_row and prev_row[c]) or fill or _next_random_tile(self) or self.config.default_tile
        end
    end

    local cfg = self.config
    cfg.n_rows, cfg.n_cols = n_rows, n_cols
    self:hard_set_T(self.T.x, self.T.y, n_cols * self.tile_w, n_rows * self.tile_h)

    _rebuild_chunks(self)
    self:mark_all_chunks_dirty()

    local gm = self.gm
    if gm.bg == self and gm.camera then gm.camera:set_bounds_from_tiledmap(self) end
end

--------------------------------------------------
--- tile_to_local
--------------------------------------------------
function TiledMap:tile_to_local(r_idx, c_idx) return (c_idx - 1) * self.tile_w, (r_idx - 1) * self.tile_h end
end
