local Y, N = true, false

local M = {}

-----------------------------
--- draw
----------------------------------
--- Helper: child layer
local function _child_layer(child, key) return child and child.config and child.config[key] end

local function _draw_order(child, fallback)
    local order = _child_layer(child, "draw_order")
    if type(order) == "number" then return order end
    return fallback or 0
end

local function _has_ordered_children(children)
    for _, child in ipairs(children or {}) do
        if _child_layer(child, "draw_order") or _child_layer(child, "shadow_layer") or _child_layer(child, "face_layer") then return Y end
    end
end

--- Helper: draw entries
local function _draw_entries(children)
    local out = {}
    for i, child in ipairs(children or {}) do
        local has_order    = _child_layer(child, "draw_order") ~= nil
        local base_order   = _draw_order(child, has_order and i or (-100000 + i))
        local face_layer   = _child_layer(child, "face_layer") or _child_layer(child, "shadow_layer")
        local shadow_layer = _child_layer(child, "shadow_layer") or face_layer
        if not face_layer and shadow_layer then face_layer = shadow_layer end

        if shadow_layer and _child_layer(child, "shadow") ~= N then out[#out + 1] = { child = child, order = shadow_layer, pass = "shadow", pass_order = 1, i = i } end
        if face_layer then out[#out + 1] = { child = child, order = face_layer, pass = "face", pass_order = 2, i = i }
        else out[#out + 1] = { child = child, order = base_order, pass = "full", pass_order = 2, i = i } end
    end

    table.sort(out, function(a, b)
        if a.order ~= b.order           then return a.order < b.order end
        if a.pass_order ~= b.pass_order then return a.pass_order < b.pass_order end
        return a.i < b.i
    end)
    return out
end

function M.draw(children)
    children = children or {}
    if not _has_ordered_children(children) then for _, child in ipairs(children) do child:draw() end; return end

    for _, entry in ipairs(_draw_entries(children)) do
        if     entry.pass == "shadow" then entry.child:draw({ shadow_only = Y })
        elseif entry.pass == "face"   then entry.child:draw({ skip_shadow = Y })
        else                               entry.child:draw() end
    end
end

return M
