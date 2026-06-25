local Y, N = true, false

local M = {}

---____________________________
--- main: ease
---______________________________________
function M.ease(gm, tab, key, to, delay)
    if not tab or to == nil then return Y end
    local EM = gm and gm.E_MANAGER;              if not EM then tab[key] = to; return Y end
    EM:enqueue_event({ trigger = "ease", ease = "sine", blockable = N, blocking = N, ref_table = tab, ref_value = key, ease_to = to, delay = delay })
    return Y
end

---____________________________
--- main: after
---______________________________________
function M.after(gm, at, fn)
    local EM = gm.E_MANAGER;                     if not EM then return fn() end
    if (at or 0) <= 0 then return fn() end
    EM:enqueue_event({ trigger = "after", delay = at, blockable = N, blocking = N, func = fn })
end

---____________________________
--- main: queue_after
---______________________________________
function M.queue_after(gm, delay, fn)
    local EM = gm.E_MANAGER;                     if not EM then return fn() end
    EM:enqueue_event({ trigger = "after", delay = delay, blockable = N, blocking = N, func = fn })
end

-----------------------------
--- color_alpha | remove_list | append_list
----------------------------------
function M.color_alpha(color) return type(color) == "table" and (color[4] == nil and 1 or color[4]) end
function M.remove_list(list) for _, actor in ipairs(list or {}) do actor:remove() end end
function M.append_list(dst, src) for _, actor in ipairs(src or {}) do dst[#dst + 1] = actor end end

---____________________________
--- main: disable_hover
---______________________________________
function M.disable_hover(actor, disabled)
    local hover = actor and actor.states and actor.states.hover;     if not hover then return end
    if disabled then
        if actor.page_switch_hover_can == nil then actor.page_switch_hover_can = hover.can end
        hover.can, hover.is = N, N
        return
    end
    if actor.page_switch_hover_lock then return end
    if actor.page_switch_hover_can ~= nil then hover.can = actor.page_switch_hover_can end
    actor.page_switch_hover_can = nil
end

---____________________________
--- main: hover_lock_tree
---______________________________________
function M.hover_lock_tree(widget, token)
    if not widget then return end
    widget.page_switch_hover_lock = token or Y
    M.disable_hover(widget, Y)
    for _, child in ipairs(widget.children or {}) do M.hover_lock_tree(child, token) end
end

---____________________________
--- main: hover_unlock_tree
---______________________________________
function M.hover_unlock_tree(widget, token)
    if not widget or (token and widget.page_switch_hover_lock ~= token) then return end
    widget.page_switch_hover_lock = nil
    M.disable_hover(widget, N)
    for _, child in ipairs(widget.children or {}) do M.hover_unlock_tree(child, token) end
end

---____________________________
--- main: disable_tree
---______________________________________
function M.disable_tree(widget, disabled)
    if not widget then return end
    widget.disable_button = disabled and Y
    M.disable_hover(widget, disabled)
    for _, child in ipairs(widget.children or {}) do M.disable_tree(child, disabled) end
end

-----------------------------
--- disable_list | hover_lock_list | hover_unlock_list
----------------------------------
function M.disable_list(list, disabled)   for _, actor in ipairs(list or {}) do M.disable_tree(actor, disabled) end end
function M.hover_lock_list(list, token)   for _, actor in ipairs(list or {}) do M.hover_lock_tree(actor, token) end end
function M.hover_unlock_list(list, token) for _, actor in ipairs(list or {}) do M.hover_unlock_tree(actor, token) end end

return M
