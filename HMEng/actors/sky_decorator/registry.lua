local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")
local ModelDefs     = require("HMEng.actors.sky_decorator.data.model_defs")
local TabUtils      = require("HMfns.utils.table_utils")

local _copy = TabUtils.deep_copy
local push  = table.insert

local Y, N = true, false

return function (SkyDecorator)
--------------------------------------------------
--- init sky decorator attributes
--------------------------------------------------
--- Helper: model definition | init params
local function _model_def_entry(params) local key = params.model_key or "bird1"; return key, ModelDefs[key] or ModelDefs.bird1 or {} end
local _init_param_keys = { "definition", "can_hover", "can_click", "can_drag", "draw_alpha", "scale_x", "scale_y", "offset_x", "offset_y" }

--- Helper: init_params
local function _init_params(params, def, model_cfg)
    local values = {
        definition  = params.definition or params.def or def,
        can_hover   = params.can_hover  or N,
        can_click   = params.can_click  or N,
        can_drag    = params.can_drag   or N,
        draw_alpha  = params.draw_alpha or def.draw_alpha or 1,
        scale_x     = params.scale_x    or model_cfg.scale_x,
        scale_y     = params.scale_y    or model_cfg.scale_y,
        offset_x    = params.offset_x   or model_cfg.offset_x,
        offset_y    = params.offset_y   or model_cfg.offset_y,
    }
    for _, key in ipairs(_init_param_keys) do params[key] = params[key] or values[key] end
end

---_________________________________________
--- main: init_sky_decorator_attributes
---_________________________________________
function SkyDecorator:init_sky_decorator_attributes(gm, x, y, w, h, params)
    params = params or {}
    local model_key, def = _model_def_entry(params)
    local model_cfg      = def.model or {}

    _init_params(params, def, model_cfg)

    AnimDecorator.init(self, gm, x, y, w, h, params)

    self.kind,    self.model_key          = "sky_decorator", model_key
    self.sky_def, self.base_model_scale   = def,            { x = self.model_scale.x, y = self.model_scale.y }
    if gm.refresh_render_context then gm:refresh_render_context(self) end
    self.flyover, self.param_drivers      = _copy(params.flyover or def.flyover or {}), _copy(params.param_drivers or def.param_drivers or {})
    self.elapsed, self.remove_on_finish   = params.elapsed or 0, params.remove_on_finish ~= N

    local st = self.states
    st.visible,   st.hover.can  = (params.visible ~= N), params.can_hover
    st.click.can, st.drag.can   = params.can_click,      params.can_drag

    local list = gm.sky_decorators or {}
    gm.sky_decorators    = list
    self.RSKY_DECORATOR  = list
    if getmetatable(self) == SkyDecorator then push(list, self) end

    self:_apply_flyover_pos(0)
end

--------------------------------------------------
--- remove
--------------------------------------------------
--- Helper: cleanup
local function cleanup(tab, obj) if not tab then return end; for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end; end
function SkyDecorator:remove()
    cleanup(self.RSKY_DECORATOR, self)
    AnimDecorator.remove(self)
end

end
