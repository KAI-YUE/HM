local Pawn       = require("HMEng.entities.pawn")
local ModelDefs  = require("HMEng.entities.pawn.anim_terrain_pawn.data.model_defs")
local TabUtils   = require("HMfns.utils.table_utils")

package.cpath = package.cpath .. ";./lib/L2/dll/?.so"
local L2L = require("L2L")

local _copy  = TabUtils.deep_copy
local push   = table.insert

local Y, N = true, false

--- Helper: _clamp 
local function _clamp(v, lo, hi) if lo and v < lo then return lo end; if hi and v > hi then return hi end; return v; end

return function (AnimTerrainPawn)
--------------------------------------------------
--- init anim terrain pawn attributes
--------------------------------------------------
--- Helper: model definition
local function _model_def_entry(params) local key = params.model_key or "white_birch"; return key, ModelDefs[key] or ModelDefs.white_birch end

---___________________________________________
--- main: init_anim_terrain_pawn_attributes
---___________________________________________
function AnimTerrainPawn:init_anim_terrain_pawn_attributes(gm, x, y, w, h, params)
    params = params or {}
    Pawn.init_pawn_attributes(self, gm, x, y, w, h, params)

    local model_key, model_def_entry  = _model_def_entry(params)
    local model_cfg                   = model_def_entry.model

    self.kind,       self.parent       = "anim_terrain_pawn",          params.parent or gm.field
    self.scale_mode, self.fixed_scale  = params.scale_mode or "fixed", params.fixed_scale or 1

    local st = self.states
    st.visible,     st.drag.can   = params.visible ~= N,  params.can_drag
    st.hover.can,   st.click.can  = params.can_hover,     params.can_click
    st.hide_cast.is               = (params.hide_cast == Y and Y) or N

    self.draw_scale_x,   self.draw_scale_y      = params.flip_x or 1, params.flip_y or 1
    self.model_key,      self.model_def         = model_key, params.model_def or model_def_entry.model_def
    
    self.model_fit_axis, self.model_offset      = params.fit_axis or model_cfg.fit_axis, { x = params.offset_x or model_cfg.offset_x, y = params.offset_y or model_cfg.offset_y }
    self.model_scale,    self.ground_contact_x  = { x = params.scale_x or model_cfg.scale_x, y = params.scale_y or model_cfg.scale_y }, params.ground_contact_x or model_cfg.ground_contact_x or 0
    self.model_dims,     self.draw_alpha        = { w = 1, h = 1 },                      params.draw_alpha or 1
    self.vivid_color,    self.shadow_color      = params.vivid_color or model_def_entry.vivid_color, params.shadow_color or model_def_entry.shadow_color
    self.anim_gust_cfg                          = _copy(params.anim_gust or model_def_entry.gust)

    self:load_anim_model(self.model_def)
    if params.param_values then self:set_anim_params(params.param_values) end

    local gR = gm.R
    self.RTPAWN = gR.TERRAINPAWN
    if getmetatable(self) == AnimTerrainPawn then push(self.RTPAWN, self) end
end

--------------------------------------------------
--- load anim model
--------------------------------------------------
--- Helper: refresh dimensions
local function _refresh_dimensions(self)
    local model = self.model;                       if not model then return end
    local w, h = model:getDimensions()
    self.model_dims.w, self.model_dims.h = w or 1, h or 1
end

---_________________________________________________
--- main: load_anim_model
---_________________________________________________
function AnimTerrainPawn:load_anim_model(model_def)
    if not L2L then return end
    local ok, model = pcall(L2L.loadModel, model_def);      if not ok then self.load_error = model; return end

    self.model_def, self.model, self.load_error = model_def, model, nil
    _refresh_dimensions(self)
    return model
end

--------------------------------------------------
--- set anim param
--------------------------------------------------
function AnimTerrainPawn:set_anim_param(id, value, lo, hi)
    local model = self.model;       if not (model and model.setParamValuePost and id) then return end
    local v = (lo or hi) and _clamp(value or 0, lo or -1, hi or 1) or value
    model:setParamValuePost(id, v)
    return v
end

function AnimTerrainPawn:set_param(id, value, lo, hi) return self:set_anim_param(id, value, lo, hi) end

function AnimTerrainPawn:set_anim_params(values)
    if not values then return end
    for id, value in pairs(values) do self:set_anim_param(id, value) end
    return values
end

--------------------------------------------------
--- remove
--------------------------------------------------
local function cleanup(tab, obj)  for i, v in ipairs(tab or {}) do if v == obj then table.remove(tab, i); break end end end
function AnimTerrainPawn:remove() cleanup(self.RTPAWN, self); Pawn.remove(self) end

end
