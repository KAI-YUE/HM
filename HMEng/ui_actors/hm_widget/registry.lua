local Actor         = require("HMEng.actors.actor")
local config_keys   = require("HMEng.ui_actors.hm_widget.config_keys")
local _default      = require("HMEng.ui_actors.hm_widget.prototype.sprite_preset.predrawn_circle.default")
local widget_prototype = require("HMEng.ui_actors.hm_widget.prototype.bake_preset")
local renderers     = require("HMEng.ui_actors.hm_widget.renderers")
local TabUtils      = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy

local Y, N  = true, false

return function (HMWidget)
-----------------------------
--- init hm widget attributes
----------------------------------
--- Helper: edge offset | _xy_pair
local function _edge_offset(v) local T = v or {}; return { x = T.x or 0, y = T.y or 0 } end
local function _xy_pair(v, d)  if type(v) == "number" then return { x = v, y = v } end; v = v or {}; return { x = v.x or d, y = v.y or d } end

--- Helper: fit sprite-backed widgets to atlas quad ratio
local function _fit_sprite_axis(gm, args, prototype_defaults, renderer_name)
    local T = args.T or {};     if renderer_name ~= "single_sprite" then return T end

    local axis = args.fit_axis
    if axis == nil and prototype_defaults then axis = prototype_defaults.fit_axis end
    if axis ~= "width"  and axis ~= "height" then return T end
    if axis == "width"  and (T.h ~= nil or not T.w) then return T end
    if axis == "height" and (T.w ~= nil or not T.h) then return T end

    local ratio = widget_prototype.sprite_ratio(gm, args, prototype_defaults); if not ratio then return T end
    if axis == "width"  then T.h = T.w / ratio end
    if axis == "height" then T.w = T.h * ratio end
    return T
end

--- Helper: copy config value
local function _copy_config_value(key, v)
    if key:find("_offset$")       then return _edge_offset(v) end
    if key == "sprite_mask_scale" then return _xy_pair(v, 1) end
    if key == "sprite_mask_deco_scale" then return _xy_pair(v, 1) end
    if key == "hit_scale"   or key == "text_box_scale" then return _xy_pair(v, 1) end
    if key == "hit_padding" or key == "text_padding" then return _xy_pair(v, 0) end
    return v
end

--- Helper: copy config keys
local function _copy_config_keys(dst, keys, args, prototype)
    for _, key in ipairs(keys) do
        local v = args[key]
        if v == nil then v = prototype[key] end
        if v == nil then v = _default[key] end
        dst[key] = _copy_config_value(key, v)
    end
end

--- Helper: apply state defaults
local function _apply_state_defaults(self)
    local st, cfg = self.states, self.config

    if cfg.can_hover   ~= nil then st.hover.can   = cfg.can_hover end
    if cfg.can_collide ~= nil then st.collide.can = cfg.can_collide end
    if cfg.can_drag    ~= nil then st.drag.can    = cfg.can_drag else st.drag.can = N end

    if cfg.button then
        st.collide.can, st.click.can = Y, Y
        if cfg.can_hover ~= N then st.hover.can = Y end
    end
    if cfg.button_UI then st.collide.can, st.click.can, st.hover.can = Y, Y, N end
    if cfg.can_click ~= nil then st.click.can = cfg.can_click end
    if cfg.tooltip or cfg.on_demand_tooltip or cfg.detailed_tooltip then st.collide.can = Y end
    if st.hover.can and cfg.can_collide == nil then st.collide.can = Y end
end

--- Helper: apply prototype defaults
local function _apply_prototype_defaults(self) local cfg = self.config; if cfg.type == nil and cfg.button then cfg.type = "button" end; end

--- Helper: child_widget_items
local function child_widget_items(cfg)
    local items = cfg.child_widgets
    if not items then return {} end
    if not items[1] and not (items.style or items.renderer or items.T) then return {} end
    return items[1] and items or { items }
end

--- Helper: child_widget_role
local function child_widget_role(gm, parent, item, T)
    local major = item.room_ref and gm._room_r or parent
    return { role_type = "Minor", major = major, offset = { x = T.x or 0, y = T.y or 0 }, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" }
end

--- Helper: init_child_widgets
local function init_child_widgets(self, gm, renderer)
    if renderer and renderer.handles_child_widgets then return end
    local items = child_widget_items(self.config);      if #items <= 0 then return end

    self.children = self.children or {}
    self.page_child_widgets = self.page_child_widgets or {}
    for _, item in ipairs(items) do
        local child_args = copy(item)
        local T      = child_args.T or {}
        local child  = HMWidget(gm, child_args)
        child.parent = self
        child:set_role(child_widget_role(gm, self, child_args, T))
        self.children[#self.children + 1] = child
        self.page_child_widgets[#self.page_child_widgets + 1] = child
    end
end

---____________________________
--- main: init_hmwidget_attributes
---____________________________
function HMWidget:init_hmwidget_attributes(gm, args)
    local T = args.T or {}
    local prototype_defaults = widget_prototype.defaults(args, _default)
    local renderer_name = args.renderer or prototype_defaults.renderer or _default.renderer
    T = _fit_sprite_axis(gm, args, prototype_defaults, renderer_name)

    Actor.init(self, gm, { T = { x = T.x or 0, y = T.y or 0, w = T.w or 10, h = T.h or 4, r = T.r, scale = T.scale } })

    self.config = {}

    local renderer = renderers[renderer_name] or renderers.stitched_rect
    _copy_config_keys(self.config, config_keys, args, prototype_defaults)
    self.config.renderer = renderer_name
    if renderer.config_keys then _copy_config_keys(self.config, renderer.config_keys, args, prototype_defaults) end

    _apply_prototype_defaults(self)
    if renderer.init then renderer.init(self, gm) end
    init_child_widgets(self, gm, renderer)
    _apply_state_defaults(self)
end

end
