local Actor = require("HMEng.actors.actor")

local push = table.insert
local ceil, min = math.ceil, math.min

local Tst    = { "drag", "hover", "click" }
local Tcfg   = { "type",       "n_rows", "n_cols", "tile_w", "tile_h", "chunk_rows", "chunk_cols", "atlas_key" }
local Tvals  = { "field_board", 1,         1,          1,         1,           8,           8,      "map" }
local Tself  = { "n_rows", "n_cols", "tile_w", "tile_h", "atlas_key", "tile_shader", "tile_shader_opts" }

local Y, N = true, false

return function (TiledMap)
--------------------------------------------------
--- init_map_attributes
--------------------------------------------------
--- Helper: _init_config_defaults
local function _init_config_defaults(cfg) for i, k in ipairs(Tcfg) do cfg[k] = cfg[k] or Tvals[i] end end

--- Helper: build chunk
local function _build_chunk(cfg, n_rows, n_cols, chunk_r, chunk_c)
    local r1, r2  = (chunk_r - 1)*cfg.chunk_rows + 1, min(chunk_r*cfg.chunk_rows, n_rows)
    local c1, c2  = (chunk_c - 1)*cfg.chunk_cols + 1, min(chunk_c*cfg.chunk_cols, n_cols)
    return { row = chunk_r, col = chunk_c, dirty = Y, r1  = r1, r2  = r2, c1  = c1, c2  = c2 }
end

--- Helper: init chunks 
local function _init_chunks(self)
    local cfg = self.config
    local n_chunk_rows, n_chunk_cols = ceil(self.n_rows / cfg.chunk_rows), ceil(self.n_cols / cfg.chunk_cols)

    self.chunks = {}
    for chunk_r = 1, n_chunk_rows do
        local row = {}
        self.chunks[chunk_r] = row
        for chunk_c = 1, n_chunk_cols do row[chunk_c] = _build_chunk(cfg, self.n_rows, self.n_cols, chunk_r, chunk_c) end
    end
end

--- Helper: init tiles
local function _init_tiles(self)
    local fill = self.config.default_tile
    for r = 1, self.n_rows do
        local row = {}
        self.tiles[r] = row
        for c = 1, self.n_cols do row[c] = fill end
    end
end

---_________________________________
--- main: init map attributes
---_________________________________
function TiledMap:init_map_attributes(gm, x, y, w, h, config)
    Actor.init(self, gm, x, y, w, h)

    self.config   = config or {}
    local cfg, T  = self.config, self.T
    _init_config_defaults(cfg)
    if gm.refresh_render_context then gm:refresh_render_context(self) end

    for _, k in ipairs(Tself) do self[k] = cfg[k] end
    self.tiles,  self.missing_keys  = {}, {}
    self:hard_set_T(x or T.x, y or T.y, w or (self.n_cols*self.tile_w), h or (self.n_rows*self.tile_h))

    self.t_shaders  = gm.t_shaders
    self.atlas      = (gm.T_atlas or {})[self.atlas_key]
    self.atlas_dims = {}
    if self.atlas and self.atlas.image then self.atlas_dims[1], self.atlas_dims[2] = self.atlas.image:getDimensions() end

    local st = self.states
    for _, k in ipairs(Tst) do st[k].can = N end

    _init_chunks(self)
    _init_tiles(self)
    self:init_tile_entry()
    self:settle_random_tiles()

    local gR = gm.R;            self.RMAP = gR.TMAP
    if getmetatable(self) == TiledMap then push(self.RMAP, self) end
end

--------------------------------------------------
--- remove
--------------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
function TiledMap:remove()
    self.tiles, self.chunks, self.atlas = nil, nil, nil
    cleanup(self.RMAP, self)
    Actor.remove(self)
end

end
