local Motion          = require("HMEng.ui_actors.common.motion")
local AnimUtils       = require("HMfns.animate.transitions.anim_utils")
local MenuTransitions = require("HMfns.animate.transitions.menu_transitions")

local _spring_draw_offset = Motion.spring_draw_offset

local _queue                  = "opt_menu_enter"
local _exit_queue             = "opt_menu_exit"
local _mini_cut_in_delay      = 0.5
local _mini_start             = 0.16
local _gear_start             = 0.34
local _textfx_start           = 0.82
local _textfx_stagger         = 0.24
local _curtain_time           = 0.9
local _mini_page_dilation     = 2
local _gear_dilation          = 2
local _mini_page_from         = { x = 2,    y = -6.2 }
local _pull_to                = { x = 2,    y = -6.2 }
local _pull_time              = 0.62
local _curtain_pull_y         = -6.2
local _gear_from              = { x = 0.35, y = -4.6 }

local _mini_page_spring = {
    { t = 0.34, x =  0.10,  y =  0.42, ease = "sine" },
    { t = 0.20, x = -0.05,  y = -0.19, ease = "sine" },
    { t = 0.16, x =  0.025, y =  0.08, ease = "sine" },
    { t = 0.12, x =  0,     y =  0,    ease = "sine" },
}

local _gear_spring = {
    { t = 0.30, x =  0.08,  y =  0.55, ease = "sine" },
    { t = 0.18, x = -0.04,  y = -0.25, ease = "sine" },
    { t = 0.14, x =  0.02,  y =  0.10, ease = "sine" },
    { t = 0.12, x = -0.01,  y = -0.04, ease = "sine" },
    { t = 0.10, x =  0,     y =  0,    ease = "sine" },
}

local M = {}

--- Helper: _mini_at | _ease | _after 
local function _mini_at(delay) return _mini_cut_in_delay + delay end
local function _ease(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _queue) end
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end

--- Helper: _ease_exit
local function _ease_exit(gm, tab, key, to, delay, ease) return AnimUtils.ease(gm, tab, key, to, delay, ease, _exit_queue) end

--- Helper: _dilated_spring
local function _dilated_spring(spring, dilation)
    if (dilation or 1) == 1 then return spring end
    local dilated = {}
    for i, step in ipairs(spring or {}) do dilated[i] = { t = (step.t or 0)*dilation, x = step.x, y = step.y, ease = step.ease } end
    return dilated
end

--- Helper: _own_color
local function _own_color(tab)
    if type(tab) ~= "table" then return end
    local owned = {}
    for k, v in pairs(tab) do owned[k] = v end
    return owned
end

--- Helper: _target_alpha
local function _target_alpha(color) return type(color) == "table" and (color[4] == nil and 1 or color[4]) or 1 end

--- Helper: _pull_point_y
local function _pull_point_y(gm, point, dy)
    if type(point) ~= "table" then return end
    _ease_exit(gm, point, "y", (point.y or point[2] or 0) + dy, _pull_time, "sine")
end

--- Helper: _pull_polygon_curtain
local function _pull_polygon_curtain(gm, root)
    local polygons = root and root.config and root.config.page_region_polygons;     if not polygons then return end
    for _, polygon in ipairs(polygons) do
        for _, point in ipairs(polygon.points or polygon) do _pull_point_y(gm, point, _curtain_pull_y) end
    end
end

--- Helper: _pull_split_stroke
local function _pull_split_stroke(gm, root)
    local split = root and root.config and root.config.split;       if not split then return end
    _ease_exit(gm, split, "y", (split.y or 0) + _curtain_pull_y, _pull_time, "sine")
end

--- Helper: _pull_mini_page
local function _pull_mini_page(gm, mini)
    if not mini then return end
    _ease_exit(gm, mini, "draw_offset_x", (mini.draw_offset_x or 0) + (_pull_to.x or 0), _pull_time, "sine")
    _ease_exit(gm, mini, "draw_offset_y", (mini.draw_offset_y or 0) + (_pull_to.y or 0), _pull_time, "sine")
end

--- Helper: _fade_polygon_curtain
local function _fade_polygon_curtain(gm, root)
    local polygons = root and root.config and root.config.page_region_polygons;     if not polygons then return end
    for _, polygon in ipairs(polygons) do
        local color = _own_color(polygon.color)
        if color then
            local alpha = _target_alpha(color)
            polygon.color = color
            color[4] = 0
            _after(gm, _mini_at(_mini_start), function() return _ease(gm, color, 4, alpha, _curtain_time, "sine") end)
        end
    end
end

--- Helper: _spring_mini_page | spring_gear 
local function _spring_mini_page(gm, mini) _spring_draw_offset(gm, mini, "_opt_menu_mini_page_enter", _mini_page_from, _dilated_spring(_mini_page_spring, _mini_page_dilation), _mini_at(_mini_start), _queue) end
local function _spring_gear(gm, mini)  for _, child in ipairs(mini.page_child_widgets or {}) do  if child.config and child.config.quad_key == "gear" then _spring_draw_offset(gm, child, "_opt_menu_mini_gear_enter", _gear_from, _dilated_spring(_gear_spring, _gear_dilation), _mini_at(_gear_start), _queue) end end end

--- Helper: _reveal_textfx
local function _reveal_textfx(gm, mini)
    MenuTransitions.fade_in_textfx(gm, mini, {
        bg_after_page_delay = _mini_at(_textfx_start),
        text_after_bg_delay = 0.18,
        bg_fade_time        = 0.24,
        text_fade_time      = 0.36,
        stagger             = _textfx_stagger,
        lock                = 1.2,
    })
end

--- Helper: fade_in
function M.fade_in(gm, mini, root)
    if not mini then return end

    _spring_mini_page(gm, mini)
    _spring_gear(gm, mini)
    _fade_polygon_curtain(gm, root)
    _reveal_textfx(gm, mini)
end

--- Helper: pull_out
function M.pull_out(gm, mini, root)
    _pull_mini_page(gm, mini)
    _pull_polygon_curtain(gm, root)
    _pull_split_stroke(gm, root)
    return _pull_time
end

return M
