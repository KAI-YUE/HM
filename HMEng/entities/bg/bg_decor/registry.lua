local Actor  = require("HMEng.actors.actor")

local Tst    = { "drag", "hover", "click" }
local Tcfg   = { "type",        "atlas_key", "tile_w", "tile_h", "visible", "spawn_pr", "cen2side_k", "cen2side_offset_u", "num_groups", "perform_cycle", "group_cycle_s", "group_cycle_start", "group_fade_s", "wipe_reborn" }
local Tval   = { "field_dec",   "grass_dec",   nil,     nil,     true,      0.3,          1,             0.75,                1,            true,            10.5,             1,                   4,              0.5 }
local Tself  = { "atlas_key", "tile_w", "tile_h", "num_groups", "perform_cycle", "group_cycle_s", "group_cycle_start", "group_fade_s", "wipe_reborn" }
local Ttab   = { "entries", "missing_keys", "atlas_dims", "group_states" }

local Y, N   = true, false

--- Helper: init config defaults 
local function _init_config_defaults(cfg) for i, k in ipairs(Tcfg) do cfg[k] = cfg[k] or Tval[i] end end

return function (BgDecor)
--------------------------------------------------
--- init_bg_decor_attributes
--------------------------------------------------
function BgDecor:init_bg_decor_attributes(gm, x, y, w, h, config)
    Actor.init(self, gm, x, y, w, h)

    self.config = config or {};     local cfg, T = self.config, self.T
    _init_config_defaults(cfg);     for _, k in ipairs(Tself) do self[k] = cfg[k] end 
    if gm.refresh_render_context then gm:refresh_render_context(self) end

    for _, k in ipairs(Ttab) do self[k] = {} end 

    local atlas = gm.T_atlas[self.atlas_key]
    self.atlas,         self.t_shaders      = atlas, gm.t_shaders
    self.atlas_dims[1], self.atlas_dims[2]  = atlas.image:getDimensions() 
    self.group_cycle_t, self.draw_alpha     = 0, 1

    self:init_entries()
    self:init_group_states()

    self.active_group = nil
    if self.perform_cycle then self:set_active_group(self.group_cycle_start)
    else                       self:sync_group_states() end

    local st   = self.states
    st.visible = cfg.visible
    for _, k in ipairs(Tst) do st[k].can = N end

    self.board, self.boardzone = nil, nil
end

--------------------------------------------------
--- remove
--------------------------------------------------
function BgDecor:remove()
    local boardzone = self.boardzone
    if boardzone and boardzone.bg_decor == self then boardzone.bg_decor = nil end
    if self.parent == boardzone                 then self.parent = nil end

    self.entries, self.missing_keys, self.atlas, self.atlas_dims, self.group_states = nil, nil, nil, nil, nil
    self.group_cycle_t,  self.board, self.boardzone = nil, nil, nil
    Actor.remove(self)
end

end
