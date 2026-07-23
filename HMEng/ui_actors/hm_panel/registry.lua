local Actor     = require("HMEng.actors.actor")
local HMWidget  = require("HMEng.ui_actors.hm_widget")
local widget_prototype = require("HMEng.ui_actors.hm_widget.prototype.bake_preset")
local TabUtils  = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy
local push = table.insert

local Y, N = true, false

return function (HMPanel)
-----------------------------
--- init hmpanel attributes
----------------------------------
--- Helper: _room_box | widget_args | _copy_box
local function _room_box(room)            local RT, w, h = room.T, 11.5, 4.6; return { x = 0.5 * (RT.w - w), y = RT.h - h - 1.4, w = w, h = h } end
local function _widget_args(args, boxT)   local wargs = copy(args); wargs.T = { x = boxT.x, y = boxT.y, w = boxT.w, h = boxT.h }; return wargs end
local function _copy_box(T)               return { x = T.x, y = T.y, w = T.w, h = T.h, r = T.r, scale = T.scale } end
local function _attached_widget(gm, args) return args.attached_panel and HMWidget(gm, copy(args.attached_panel)) end

--- Helper: set interaction layer
local function _set_interaction_layer(node, layer)
    if not node then return end
    node.interaction_layer = layer
    for _, child in ipairs(node.children or {}) do _set_interaction_layer(child, layer) end
    for _, child in ipairs(node.page_child_widgets or {}) do _set_interaction_layer(child, layer) end
    for _, child in ipairs(node.page_card_textfx or {}) do _set_interaction_layer(child, layer) end
end

--- Helper: panel prototype defaults
local function _panel_prototype_defaults(args)
    local style = args.panel_style or args.style
    if type(style) ~= "string" then return end

    local module = "HMEng.ui_actors.hm_panel.prototype." .. style
    local path = module:gsub("%.", "/")
    for search in string.gmatch(package.path, "[^;]+") do
        local filename = search:gsub("%?", path)
        local f = io.open(filename, "r")
        if f then f:close(); return require(module) end
    end
end

--- Helper: panel_args
local function _panel_args(args, prototype)
    if not prototype then return args end

    local pargs = copy(prototype)
    for k, v in pairs(args) do pargs[k] = v end

    if     args.widget_style then pargs.style = args.widget_style
    elseif args.panel_style  then pargs.style = args.style or prototype.widget_style
    elseif args.style        then pargs.style = prototype.widget_style end
    return pargs
end

--- Helper: fit panel box to sprite ratio
local function _fit_axis_box(gm, args, boxT, prototype)
    local axis = args.fit_axis
    if axis == nil and prototype then axis = prototype.fit_axis end; if not axis or axis == "none" then return boxT end
    local ratio = widget_prototype.sprite_ratio(gm, args, prototype); if not ratio then return boxT end

    if     axis == "width"  then  boxT.h = boxT.w / ratio
    elseif axis == "height" then  boxT.w = boxT.h * ratio
    elseif axis == "square" then  local s = math.min(boxT.w, boxT.h); boxT.w, boxT.h = s, s end
    return boxT
end

---____________________________
--- main: init_hmpanel_attributes
---______________________________________
function HMPanel:init_hmpanel_attributes(gm, args)
    local pargs      = _panel_args(args, _panel_prototype_defaults(args))
    local prototype  = widget_prototype.defaults(pargs)
    local boxT       = _fit_axis_box(gm, pargs, _copy_box(pargs.T or _room_box(gm._room)), prototype)

    Actor.init(self, gm, boxT.x, boxT.y, boxT.w, boxT.h)
    self.gm, self.UI = gm, gm.UI

    local _widget  = HMWidget(gm, _widget_args(pargs, boxT))
    self.widget    = _widget
    _widget.parent = self
    _widget:set_role({ role_type = "Minor", major = self, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" })

    self.attached_panel = _attached_widget(gm, pargs)

    local IREG = gm.R.UIPANEL
    if pargs.config and pargs.config.instance_type then IREG = gm.R[pargs.config.instance_type] or IREG end
    push(IREG, self)
    self.IREG = IREG

    if pargs.modal_cursor_context then
        self.modal_cursor_context = Y; self.Ctrl:mod_cursor_context_layer(1)
        local layer = self.Ctrl.cursor_context and self.Ctrl.cursor_context.layer
        _set_interaction_layer(self.widget, layer); _set_interaction_layer(self.attached_panel, layer)
    end
end

-----------------------------
--- remove
----------------------------------
local function cleanup(tab, obj)        for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
--- Helper: remove_switch_attached_panels
local function remove_switch_attached_panels(panel) for _, old_panel in ipairs(panel.switch_attached_panels or {}) do old_panel:remove() end; panel.switch_attached_panels = nil end

function HMPanel:remove()
    if self.modal_cursor_context then  self.modal_cursor_context = nil; self.Ctrl:mod_cursor_context_layer(-1) end

    local IREG = self.IREG
    if IREG then cleanup(IREG, self) end
    remove_switch_attached_panels(self)
    if self.attached_panel then self.attached_panel:remove(); self.attached_panel = nil end
    if self.widget then self.widget:remove(); self.widget = nil end
    Actor.remove(self)
end

end
