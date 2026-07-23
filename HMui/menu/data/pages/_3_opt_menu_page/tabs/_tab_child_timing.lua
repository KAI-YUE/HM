local max, min = math.max, math.min

local M = {}

--- Helpers: enter_count | enter_end
local function _enter_count(child)  if not child or not child.page_switch_stagger_children then return 1 end; return min(child.visible_count or #(child.child_widgets or {}), #(child.child_widgets or {})) end
local function _enter_end(child)
    if not child then return end
    local start = child.page_switch_enter_start; if not start then return end
    local count = max(1, _enter_count(child))
    return start + (child.page_switch_enter_stagger or 0)*(count - 1) + (child.page_switch_enter_time or 0)
end

------------------------------------------
--- control_lock_delay
------------------------------------------
function M.control_lock_delay(child_widgets, fallback)
    local delay = fallback
    for _, child in ipairs(child_widgets or {}) do
        local enter_end = _enter_end(child)
        if enter_end and (not delay or enter_end > delay) then delay = enter_end end
    end
    return delay
end

return M
