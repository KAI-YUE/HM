local Common   = require("HMui.menu.data.pages._-1_title_page.anims.common")
local Timeline = require("HMui.menu.data.pages._-1_title_page.anims.timeline")

local _ease  = Common.ease
local _after = Common.after

local Y = true

local M = {}

local _key = "_title_press_hat"

--- Helper: _set_drop_start
local function _set_drop_start(widget, from_y)
    Common.cache_widget(widget, _key)
    local normal = widget and widget[_key .. "_offset"]; if not normal then return end
    widget.draw_offset_x, widget.draw_offset_y = normal.x, normal.y + (from_y or -6)
    widget.draw_alpha = 0
end

--- Helper: _drop_in
local function _drop_in(gm, widget, delay)
    if not widget then return end
    local normal = widget[_key .. "_offset"];       if not normal then return end
    _after(gm, delay, function()
        if widget.REMOVED then return Y end
        _ease(gm, widget, "draw_alpha", widget[_key].draw_alpha or 1, 0.12, "lerp")
        _ease(gm, widget, "draw_offset_y", normal.y + 0.22, 0.24, "sine")
        return Y
    end)

    _after(gm, delay + 0.24, function()
        if widget.REMOVED then return Y end
        _ease(gm, widget, "draw_offset_y", normal.y - 0.08, 0.12, "sine")
        return Y
    end)
    
    _after(gm, delay + 0.36, function() if widget.REMOVED then return Y end; _ease(gm, widget, "draw_offset_y", normal.y, 0.14, "sine"); return Y; end)
    _after(gm, delay + 0.54, function() return Common.restore_widget(widget, _key) end)
end

----------------------------------------------
--- main: start
----------------------------------------------
function M.start(gm, widgets)
    _set_drop_start(widgets.chef_hat_mask, -6.4)
    _set_drop_start(widgets.chef_hat_pad, -6.4)
    _set_drop_start(widgets.chef_hat, -6.4)

    _drop_in(gm, widgets.chef_hat_mask, Timeline.press_decorators.hat_drop)
    _drop_in(gm, widgets.chef_hat_pad,  Timeline.press_decorators.hat_drop)
    _drop_in(gm, widgets.chef_hat,      Timeline.press_decorators.hat_drop)
end

return M
