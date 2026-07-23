local Data           = require("HMui.menu.data.pages._4_deck_preview_page.preview_layout")
local AnimUtils      = require("HMfns.animate.transitions.anim_utils")
local PhysicsMotion  = require("HMEng.ui_actors.common.physics_motion")

local cos, pi  = math.cos, math.pi

local Y, N = true, false

local M  = {}

local _key    = "_deck_preview_floating_log"
local _token  = "_deck_preview_floating_log_token"
local _queue  = "deck_preview_floating_log"
local _phase  = "_deck_preview_floating_log_phase"
local _start  = "_deck_preview_floating_log_start"
local _group  = "_deck_preview_floating_log_group"

--- Helper: after
local function _after(gm, delay, fn) return AnimUtils.after(gm, delay, fn, _queue) end

-----------------------------
--- floating subtree
-----------------------------
--- Helper: collect nodes
local function _collect(node, out)
    if not node then return out end
    out[#out + 1] = node
    for _, child in ipairs(node.children or {}) do _collect(child, out) end
    return out
end

--- Helper: cache nodes
local function _cache(widget)
    if widget[_key] then return widget[_key] end
    local state = { nodes = {} }
    
    for _, node in ipairs(_collect(widget, {})) do
        state.nodes[#state.nodes + 1] = {
            node  = node,                    x  = node.draw_offset_x or 0, 
            r     = node.draw_rotate or 0,   y  = node.draw_offset_y or 0,
        }
    end

    widget[_key] = state
    return state
end

--- Helper: apply frame
local function _apply(state, x, y, r)
    for _, entry in ipairs(state.nodes) do
        local node = entry.node
        if not node.REMOVED then node.draw_offset_x, node.draw_offset_y, node.draw_rotate = entry.x + x, entry.y + y, entry.r + r end
    end
end

--- Helper: restore frame
local function _restore_frame(state, from, p)
    for i, entry in ipairs(state.nodes) do
        local node, origin = entry.node, from[i]
        if node.REMOVED then goto continue end
        node.draw_offset_x  = origin.x + (entry.x - origin.x)*p
        node.draw_offset_y  = origin.y + (entry.y - origin.y)*p
        node.draw_rotate    = origin.r + (entry.r - origin.r)*p

        ::continue::
    end
end

--- Helper: restore
local function _restore(widget, token)
    local state    = widget and widget[_key];                 if not state then return end
    local gm, cfg  = widget.gm, Data.floating_log
    local start, duration, from = gm._T.real_s or 0, cfg.return_time or 0.24, {}
    
    for i, entry in ipairs(state.nodes) do
        local node = entry.node
        from[i] = { x = node.draw_offset_x or 0, y = node.draw_offset_y or 0, r = node.draw_rotate or 0 }
    end

    local function tick()
        if widget.REMOVED or widget[_token] ~= token then return Y end
        local p = math.min(1, ((gm._T.real_s or start) - start)/duration)
        _restore_frame(state, from, 0.5 - 0.5*cos(pi*p))
        if p < 1 then _after(gm, cfg.step or (1/60), tick) end
        return Y
    end
    return tick()
end

--- Helper: motion group
local function _motion_group(widget)
    local owner = widget.parent or widget
    owner[_group] = owner[_group] or {}
    return owner[_group]
end

--- Helper: stop floating
local function _stop_float(widget)
    if not widget then return end
    widget[_token] = (widget[_token] or 0) + 1
    return _restore(widget, widget[_token])
end

--- Helper: start floating
local function _start_float(widget, phase, start, stop_when, on_stop)
    widget[_token] = (widget[_token] or 0) + 1
    local token, gm, state = widget[_token], widget.gm, _cache(widget)
    local cfg = Data.floating_log
    local motion_cfg = setmetatable({ phase = phase or 0 }, { __index = cfg })

    local function tick()
        if widget.REMOVED or widget[_token] ~= token then return Y end
        if stop_when and stop_when() then return on_stop and on_stop() or Y end
        local t = (gm._T.real_s or start) - start
        local x, y, r = PhysicsMotion.floating_log_offset(motion_cfg, t)

        _apply(state, x, y, r)
        _after(gm, cfg.step or (1/60), tick)
        return Y
    end
    return tick()
end

--- Helper: resume active
local function _resume_active(group)
    local active = group.active;                         if not active or active.REMOVED then return end
    local hovered = group.hover
    if hovered and hovered.states.hover.is then return end
    return _start_float(active, active[_phase], active[_start] or (active.gm._T.real_s or 0))
end

---____________________________
--- main: set_active
---______________________________________
function M.set_active(widget, active, phase)
    if not widget then return end
    local group = _motion_group(widget)
    widget[_phase] = phase or 0

    if not active then
        if group.active == widget then group.active = nil end
        return _stop_float(widget)
    end

    group.active, widget[_start] = widget, widget.gm._T.real_s or 0
    if group.hover == widget then group.hover = nil end
    if group.hover and group.hover.states.hover.is then return _stop_float(widget) end
    return _start_float(widget, widget[_phase], widget[_start])
end

---____________________________
--- main: hover
---______________________________________
function M.hover(widget)
    if not widget or widget.disable_button then return end
    local group, start = _motion_group(widget), widget.gm._T.real_s or 0
    if group.hover and group.hover ~= widget then _stop_float(group.hover) end
    group.hover = widget
    _stop_float(group.active)

    local function stop_when() return widget.disable_button or not widget.states.hover.is end
    local function on_stop()
        if group.hover == widget then group.hover = nil end
        _stop_float(widget)
        return _resume_active(group)
    end
    return _start_float(widget, widget[_phase], start, stop_when, on_stop)
end

return M
