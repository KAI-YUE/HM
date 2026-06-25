local M = {}

--- Helper: _axis_offset
local function _axis_offset(value, size, text_size, center, last, center_alias)
    if value == center or value == center_alias then return 0.5*(size - text_size) end
    if value == last   then return size - text_size end
    return 0
end

function M.xy(align, w, h, tw, th)
    align = type(align) == "table" and align or {}
    return _axis_offset(align.x or "center", w, tw, "center", "right", "middle"),
           _axis_offset(align.y or "middle", h, th, "middle", "bottom", "center")
end

return M
