local TabUtils = require("HMfns.utils.table_utils")

local copy = TabUtils.deep_copy
local max, min = math.max, math.min

local M = {}

M.ordered = {
    require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_1_audio"),
    require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_2_vision"),
    require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_3_control"),
    require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system"),
}

M.active_key = "opt_system"

local idle_layout = { left = 0.16, gap = 0.05, char_w = 0.035, base_h = 0.18, char_h = 0.012, y_lift = 0.05 }

--- Helper: idle_tab_width
local function idle_tab_width(tab)
    local text = tab and (tab.text or tab.text_i18n_key or tab.key) or ""
    return #tostring(text) * idle_layout.char_w
end

--- Helper: idle_tab_y
local function idle_tab_y(tab)
    local text = tab and (tab.text or tab.text_i18n_key or tab.key) or ""
    local h = idle_layout.base_h + #tostring(text) * idle_layout.char_h
    return (tab.y or 0) - h*idle_layout.y_lift
end

--- Helper: line_positions
local function line_positions(tabs)
    local out, cursor = {}, idle_layout.left
    for i, tab in ipairs(tabs or {}) do
        if i >= 4 then break end
        local w = idle_tab_width(tab)
        out[i] = { x = cursor + 0.5*w, y = idle_tab_y(tab), r = tab.r }
        cursor = cursor + w + idle_layout.gap
    end
    return out
end

M.line_positions  = line_positions(M.ordered)
M.active_position = { x = M.ordered[4].x, y = M.ordered[4].y, r = M.ordered[4].r }
M.by_key = {}
for _, tab in ipairs(M.ordered) do M.by_key[tab.key] = tab end

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
--- Helper: child_enter_count
local function child_enter_count(child)
    if not child or not child.page_switch_stagger_children then return 1 end
    return min(child.visible_count or #(child.child_widgets or {}), #(child.child_widgets or {}))
end

--- Helper: child_enter_end
local function child_enter_end(child)
    if not child then return end
    local start = child.page_switch_enter_start;     if not start then return end
    local count = max(1, child_enter_count(child))
    return start + (child.page_switch_enter_stagger or 0)*(count - 1) + (child.page_switch_enter_time or 0)
end

---________________________________________
--- main: child_control_lock_delay
---________________________________________
function M.child_control_lock_delay(child_widgets, fallback)
    local delay = fallback
    for _, child in ipairs(child_widgets or {}) do
        local enter_end = child_enter_end(child)
        if enter_end and (not delay or enter_end > delay) then delay = enter_end end
    end
    return delay
end

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

    for i, key in ipairs(state.queue or {}) do
        local tab, pos = copy(M.by_key[key]), M.line_positions[i]
        if not tab or not pos then goto continue end 
        tab.x, tab.y, tab.r = pos.x, pos.y, pos.r
        list[#list + 1] = tab
        ::continue::
    end
    return list
end

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
