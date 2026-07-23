local Motion    = require("HMEng.ui_actors.common.motion")
local Tree      = require("HMEng.ui_actors.common.tree")
local AnimUtils = require("HMfns.animate.transitions.anim_utils")

local Y = true

local M = {}

M.queue = "title_press_any"
M.step  = 1/60

local _cache_draw_offset    = Motion.cache_draw_offset
local _restore_draw_offset  = Motion.restore_draw_offset

-----------------------------------------------------------------------------------------------------
--- after | ease | normal_draw_alpha | find | find_in_list
------------------------------------------------------------------------------------------------------
function M.after(gm, delay, fn)                return AnimUtils.after(gm, delay, fn, M.queue) end
function M.ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, M.queue) end
function M.normal_draw_alpha(widget)           return widget and (widget.page_switch_draw_alpha or widget.draw_alpha or 1) end
function M.find(root, id)                      return Tree.find_child_by_id(root, id) end
function M.find_in_list(list, id)              for _, root in ipairs(list or {}) do local found = M.find(root, id); if found then return found end; end; end

----------------------------------------------
--- cache_widget
----------------------------------------------
function M.cache_widget(widget, key)
    if not widget or widget[key .. "_cached"] then return end
    _cache_draw_offset(widget, key .. "_offset")
    widget[key] = {
        draw_alpha  = M.normal_draw_alpha(widget),
        draw_rotate = widget.draw_rotate or 0,
    }
    widget[key .. "_cached"] = Y
end

----------------------------------------------
--- restore_widget
----------------------------------------------
function M.restore_widget(widget, key)
    local normal = widget and widget[key];         if not normal then return Y end
    
    widget.draw_alpha, widget.draw_rotate = normal.draw_alpha, normal.draw_rotate
    _restore_draw_offset(widget, key .. "_offset")
    widget[key], widget[key .. "_cached"] = nil, nil
    return Y
end

return M
