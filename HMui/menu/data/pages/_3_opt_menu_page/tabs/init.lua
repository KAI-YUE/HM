local _tabs_dir    = "HMui.menu.data.pages._3_opt_menu_page.tabs."

local TabUtils     = require("HMfns.utils.table_utils")
local IdleLayout   = require(_tabs_dir .. "_tab_idle_layout")
local ChildTiming  = require(_tabs_dir .. "_tab_child_timing")

local copy = TabUtils.deep_copy

local M = {}

M.ordered = {
    require(_tabs_dir .. "_3_1_audio"),     require(_tabs_dir .. "_3_2_vision"),
    require(_tabs_dir .. "_3_3_control"),   require(_tabs_dir .. "_3_4_system"),
}

M.active_key = "opt_system"

M.line_positions  = IdleLayout.line_positions(M.ordered)
M.active_position = { x = M.ordered[4].x, y = M.ordered[4].y, r = M.ordered[4].r }
M.by_key = {}
for _, tab in ipairs(M.ordered) do M.by_key[tab.key] = tab end

--- Helper: _queue_tabs
local function _queue_tabs(state)
    local out = {}
    for _, key in ipairs((state and state.queue) or {}) do local tab = M.by_key[key]; if tab then out[#out + 1] = tab end end
    return out
end

----------------------------------
--- default_state | selected_tab
----------------------------------
function M.default_state()      return { active_key = M.active_key, queue = { "opt_audio", "opt_vision", "opt_control" } } end
function M.selected_tab(state)  return M.by_key[(state or M.default_state()).active_key] end

-----------------------------
--- selected_child_widgets
-----------------------------
function M.selected_child_widgets(state, gm)
    local tab = M.selected_tab(state)
    if tab and tab.build_child_widgets and gm then return tab.build_child_widgets(gm) end
    local child_widgets = tab and tab.child_widgets
    if not child_widgets or (not child_widgets[1] and not (child_widgets.style or child_widgets.renderer or child_widgets.T)) then return end
    return copy(child_widgets)
end

-----------------------------------------
--- child_control_lock_delay
-----------------------------------------
function M.child_control_lock_delay(child_widgets, fallback) return ChildTiming.control_lock_delay(child_widgets, fallback) end

--------------------------
--- layout_tabs
--------------------------
function M.layout_tabs(state)
    state = state or M.default_state()
    local list = {}
    local active = copy(M.by_key[state.active_key])
    if active then
        active.x, active.y, active.r = M.active_position.x, M.active_position.y, M.active_position.r
        list[#list + 1] = active
    end

    local line_positions = IdleLayout.line_positions(_queue_tabs(state))
    for i, key in ipairs(state.queue or {}) do
        local tab, pos, base_pos = copy(M.by_key[key]), line_positions[i], M.line_positions[i]
        if not tab or not pos then goto continue end 
        tab.x, tab.y, tab.r = pos.x, (base_pos or pos).y, (base_pos or pos).r
        tab.anchor_x, tab.text_align = pos.anchor_x, pos.text_align
        tab.text_fake_align_width, tab.textfx_space_bounds = pos.text_fake_align_width, pos.textfx_space_bounds
        list[#list + 1] = tab
        ::continue::
    end
    return list
end

--- Helper: idle_middle_x
function M.idle_middle_x(state) return IdleLayout.middle_x(_queue_tabs(state or M.default_state())) end

--------------------------
--- select
--------------------------
function M.select(state, key)
    state = state or M.default_state()
    if not key or key == state.active_key or not M.by_key[key] then return state end

    local old_active, queue = state.active_key, {}
    for _, item_key in ipairs(state.queue or {}) do if item_key ~= key then queue[#queue + 1] = item_key end end
    queue[#queue + 1] = old_active

    state.active_key, state.queue = key, queue
    return state
end

--------------------------
--- select_ordered
--------------------------
function M.select_ordered(state, key)
    state = state or M.default_state()
    if not key or key == state.active_key or not M.by_key[key] then return state end

    local queue = {}
    for _, tab in ipairs(M.ordered) do if tab.key ~= key then queue[#queue + 1] = tab.key end end

    state.active_key, state.queue = key, queue
    return state
end

--------------------------
--- step key
--------------------------
function M.step_key(state, step)
    state = state or M.default_state()
    local idx = 1
    for i, tab in ipairs(M.ordered) do if tab.key == state.active_key then idx = i; break end end
    local n = #M.ordered
    return M.ordered[((idx + (step or 1) - 1) % n) + 1].key
end

return M
