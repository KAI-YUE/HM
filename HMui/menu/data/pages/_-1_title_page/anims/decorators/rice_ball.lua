local PhysicsMotion = require("HMEng.ui_actors.common.physics_motion")
local Common        = require("HMui.menu.data.pages._-1_title_page.anims.common")
local Timeline      = require("HMui.menu.data.pages._-1_title_page.anims.timeline")

local _after = Common.after

local Y = true

local M = {}

local _key = "_title_press_rice"

----------------------------------------------
--- Helper: _set_start
----------------------------------------------
local function _set_start(parts, from)
    for _, widget in ipairs(parts or {}) do
        Common.cache_widget(widget, _key)
        local normal = widget and widget[_key .. "_offset"]
        if normal then
            widget.draw_offset_x, widget.draw_offset_y = normal.x + (from.x or 0), normal.y + (from.y or 0)
            widget.draw_alpha = 0
        end
    end
end

----------------------------------------------
--- Helper: _cut_in
----------------------------------------------
local function _cut_in(gm, parts, cfg, delay)
    local duration  = cfg.duration or 0.72
    local steps     = math.ceil(duration/Common.step)

    for i = 0, steps do
        local t = math.min(duration, i*Common.step)
        local p = duration > 0 and t/duration or 1
        _after(gm, delay + t, function()
            local x, y, r = PhysicsMotion.parabola_offset(cfg, p)
            for _, widget in ipairs(parts or {}) do
                local normal = widget and widget[_key .. "_offset"]
                if widget and not widget.REMOVED and normal then
                    widget.draw_offset_x = normal.x + x
                    widget.draw_offset_y = normal.y + y
                    widget.draw_rotate   = (widget[_key].draw_rotate or 0) + r
                    widget.draw_alpha    = math.min(widget[_key].draw_alpha or 1, p/0.18)
                end
            end
            return Y
        end)
    end

    _after(gm, delay + duration + 0.05, function()
        for _, widget in ipairs(parts or {}) do Common.restore_widget(widget, _key) end
        return Y
    end)
end

----------------------------------------------
--- main: start
----------------------------------------------
function M.start(gm, parts)
    _set_start(parts, { x = -4.2, y = 1.2 })
    _cut_in(gm, parts, { from_x = -4.2, from_y = 1.2, to_x = 0, to_y = 0, arc_h = 2.4, from_r = -0.9, to_r = 0, duration = 0.74 }, Timeline.press_decorators.rice_cut)
end

return M
