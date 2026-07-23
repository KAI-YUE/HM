local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.common")
local Layout = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.layout")

local N = false

local M = {}

--- Helpers: child by id | set child T
local function _child_by_id(widget, id) for _, child in ipairs((widget and widget.children) or {}) do if child.config and child.config.id == id then return child end end end
local function _set_child_T(parent, child, T)
    if not (parent and child and T) then return end
    local cfgT = child.config and (child.config.T or {}); if child.config then child.config.T = cfgT end
    if cfgT then for k, v in pairs(T) do cfgT[k] = v end end
    if child.role then child.role.offset = child.role.offset or {}; child.role.offset.x, child.role.offset.y = T.x or child.role.offset.x, T.y or child.role.offset.y end

    local ox, oy = (child.role and child.role.offset and child.role.offset.x) or T.x or 0, (child.role and child.role.offset and child.role.offset.y) or T.y or 0
    child:hard_set_T(parent.T.x + ox, parent.T.y + oy, T.w or child.T.w, T.h or child.T.h)
end

-----------------------------
--- component transforms
-----------------------------
local function _set_components(widget, id, args, layout)
    if Common.bg_underlay_enabled(args) then _set_child_T(widget, _child_by_id(widget, id .. "_bg_underlay"), Layout.bg_underlay_T(args, layout)) end
    if args._folded_cfg.bg then _set_child_T(widget, _child_by_id(widget, id .. "_bg"), Layout.bg_T(args, layout)) end
    if Common.mask_underlay_enabled(args) then _set_child_T(widget, _child_by_id(widget, id .. "_mask_underlay"), Layout.mask_underlay_T(args, layout)) end
    if args._folded_cfg.mask then _set_child_T(widget, _child_by_id(widget, id .. "_mask"), Layout.mask_T(args, layout)) end
    _set_child_T(widget, _child_by_id(widget, id .. "_icon"), Layout.icon_T(args, layout))

    local label = _child_by_id(widget, id .. args._folded_cfg.base.label_suffix)
    _set_child_T(widget, label, Layout.label_T(layout))
    if label and label.config then label.config.text_scale, label.config.text_maxw = layout.label_text_scale, layout.label_maxw end

    local frame = Layout.frame(args, layout)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_top_left"),     frame.top_left)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_top"),          frame.top)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_top_right"),    frame.top_right)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_right"),        frame.right)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_bottom_left"),  frame.bottom_left)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_bottom"),       frame.bottom)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_bottom_right"), frame.bottom_right)
    _set_child_T(widget, _child_by_id(widget, id .. "_frame_fold"),         frame.fold)
    if args.anchor_sprite ~= N then _set_child_T(widget, _child_by_id(widget, id .. "_anchor"), Layout.anchor_sprite_T(args, layout)) end
end

-----------------------------
--- main
-----------------------------
function M.apply(panel, args)
    args = Common.with_defaults(args)
    local widget = panel and (panel.widget or panel);       if not widget then return end
    local id = args.id or (widget.config and widget.config.id) or "folded_corner_btn"
    local layout = Layout.compute(args)
    local T = Layout.button_T(args, layout)

    if panel.widget and panel.hard_set_T then panel:hard_set_T(T.x, T.y, T.w, T.h) end
    if widget.hard_set_T then widget:hard_set_T(T.x, T.y, T.w, T.h) end
    _set_components(widget, id, args, layout)
    return layout
end

return M
