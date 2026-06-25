local Actor = require("HMEng.actors.actor")

package.cpath = package.cpath .. ";./lib/L2/dll/?.so"
local L2L = require("L2L")

local push = table.insert

local Y, N = true, false

return function (AnimDecorator)
-----------------------------
--- init anim decorator attributes
-----------------------------
--- Helper: _apply_transform_extras
local function _apply_transform_extras(self, cfg)
    local T = cfg and cfg.T;             if not T then return end
    if T.r     ~= nil then self.T.r,     self.VT.r     = T.r,     T.r     end
    if T.scale ~= nil then self.T.scale, self.VT.scale = T.scale, T.scale end
end

--- Helper: _apply_can_flags
local function _apply_can_flags(self, p)
    local flags = { hover = p.can_hover, collide = p.can_collide, click  = p.can_click, drag = p.can_drag }
    for state, can in pairs(flags) do if can ~= nil then self.states[state].can = can end; end
end

---____________________________
--- main: init_anim_decorator_attributes
---____________________________
function AnimDecorator:init_anim_decorator_attributes(gm, x, y, w, h, params)
    self.params, self.gm = params or {}, gm
    Actor.init(self, gm, x, y, w, h)

    local p,   def   = self.params, self.params.definition or self.params.def or {}
    local model_cfg  = def.model or {}

    self.config, self.definition = p, def
    _apply_transform_extras(self, p)

    self.model_def,     self.motion_group   = p.model_def or def.model_def, p.motion_group or def.motion_group or "normal"
    self.mesh_draw_idx, self.draw_mesh      = p.mesh_draw_idx or 0,         not not p.draw_mesh
    self.auto_load,     self.auto_update    = (p.auto_load ~= N),           (p.auto_update ~= N)
    self.draw_alpha,    self.anim_gust_cfg  = p.draw_alpha or 1,            p.anim_gust or def.anim_gust
    self.model_offset,  self.model_scale    = { x = p.offset_x or model_cfg.offset_x or 0, y = p.offset_y or model_cfg.offset_y or 0 }, { x = p.scale_x or model_cfg.scale_x or 1, y = p.scale_y or model_cfg.scale_y or 1 }
    self.model_dims,    self.model_motion   = { w = 1, h = 1 },             {}

    _apply_can_flags(self, p)

    local reg = gm.R.ANIM_DECORATOR
    self.RANIM_DECORATOR = reg

    if reg and getmetatable(self) == AnimDecorator then push(reg, self) end
    if not self.auto_load or not self.model_def    then return end
    self:load_anim_model(self.model_def)
    if self.set_anim_params then self:set_anim_params(p.param_values or def.param_values) end
end

-----------------------------
--- load anim model
-----------------------------
--- Helper: _refresh_dimensions
local function _refresh_dimensions(self)
    local model = self.model;                               if not model then return end
    local w, h = model:getDimensions()
    self.model_dims.w, self.model_dims.h = w or 1, h or 1
end

---____________________________
--- main: load_anim_model
---____________________________
function AnimDecorator:load_anim_model(model_def)
    if not L2L then return end

    local ok, model = pcall(L2L.loadModel, model_def);      if not ok then self.load_error = model; return end

    self.model_def,    self.model      = model_def, model
    self.model_motion, self.model_mesh = model.getMotionList and model:getMotionList(), model.getMesh and model:getMesh()
    self.load_error = nil

    _refresh_dimensions(self)
    return model
end

---____________________________
--- main: load_model
---____________________________
function AnimDecorator:load_model(model_def) return self:load_anim_model(model_def) end

-----------------------------
--- remove
-----------------------------
--- Helper: cleanup
local function cleanup(tab, obj) if not tab then return end; for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end

---____________________________
--- main: remove
---____________________________
function AnimDecorator:remove()
    cleanup(self.RANIM_DECORATOR, self)
    Actor.remove(self)
end

end
