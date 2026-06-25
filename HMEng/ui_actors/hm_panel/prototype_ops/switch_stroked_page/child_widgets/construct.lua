local HMWidget = require("HMEng.ui_actors.hm_widget")

local M = {}

-----------------------------
--- switch stroked_page child widget construction helpers
----------------------------------
--- Helper: child_role
local function _child_role(gm, widget, item, T)
    local major = item.room_ref and gm._room_r or widget
    return {
        role_type  = "Minor",
        major      = major,
        offset     = { x = T.x or 0, y = T.y or 0 },
        xy_bond    = "Strong",
        wh_bond    = "Strong",
        r_bond     = "Strong",
        scale_bond = "Strong",
    }
end

--- Helper: new_child
local function _new_child(gm, item, T)
    if item.actor == "anim_decorator" then
        local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")
        return AnimDecorator(gm, T.x, T.y, T.w, T.h or T.w, item)
    end
    return HMWidget(gm, item)
end

--- Helper: copy_switch_anim_config
local function _copy_switch_anim_config(child, item)
    local cfg = child and child.config;  if not cfg then return end

    cfg.page_switch_enter_start       = item.page_switch_enter_start
    cfg.page_switch_enter_stagger     = item.page_switch_enter_stagger
    cfg.page_switch_enter_time        = item.page_switch_enter_time
    cfg.page_switch_stagger_children  = item.page_switch_stagger_children
end

function M.new_list(widget, gm, child_cfg)
    local list = {};           if not child_cfg then return list end

    local items = child_cfg[1] and child_cfg or { child_cfg }
    for _, item in ipairs(items) do
        local T = item.T or {}
        local child = _new_child(gm, item, T)
        _copy_switch_anim_config(child, item)
        child.parent = widget
        child:set_role(_child_role(gm, widget, item, T))
        widget.children[#widget.children + 1] = child
        list[#list + 1] = child
    end
    return list
end

return M
