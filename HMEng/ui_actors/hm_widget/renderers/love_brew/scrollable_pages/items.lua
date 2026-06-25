local M = {}

-----------------------------
--- Item helpers
----------------------------------
local function _items(cfg)
    local items = cfg.child_widgets
    if not items then return {} end
    if not items[1] and not (items.style or items.renderer or items.T) then return {} end
    return items[1] and items or { items }
end

function M.items(cfg) return _items(cfg) end

return M
