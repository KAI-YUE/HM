local M = {}

function M.find_child_by_id(widget, id)
    if not widget then return end
    if widget.config and widget.config.id == id then return widget end
    for _, child in ipairs(widget.children or {}) do local found = M.find_child_by_id(child, id); if found then return found end end
end

return M
