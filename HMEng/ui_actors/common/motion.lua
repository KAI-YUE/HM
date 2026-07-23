local AnimUtils = require("HMfns.animate.transitions.anim_utils")

local _after, _ease = AnimUtils.after, AnimUtils.ease

local Y = true

local M = {}

------------------------------------------
--- cache_draw_offset
------------------------------------------
function M.cache_draw_offset(obj, key)
    if not obj or obj[key .. "_cached"] then return end
    obj[key] = { x = obj.draw_offset_x or 0, y = obj.draw_offset_y or 0 }
    obj[key .. "_cached"] = Y
end

------------------------------------------
--- set_draw_offset_from
------------------------------------------
function M.set_draw_offset_from(obj, key, from)
    if not obj then return end
    M.cache_draw_offset(obj, key)
    local normal = obj[key]
    obj.draw_offset_x, obj.draw_offset_y = normal.x + (from.x or 0), normal.y + (from.y or 0)
end

------------------------------------------
--- restore_draw_offset
------------------------------------------
function M.restore_draw_offset(obj, key)
    local normal = obj and obj[key];            if not normal then return Y end
    obj.draw_offset_x, obj.draw_offset_y      = normal.x, normal.y
    obj[key],          obj[key .. "_cached"]  = nil,      nil
    return Y
end

------------------------------------------
--- spring_draw_offset
------------------------------------------
function M.spring_draw_offset(gm, obj, key, from, spring, delay, queue)
    if not obj then return end
    M.set_draw_offset_from(obj, key, from)

    local normal = obj[key]
    local at     = delay or 0

    for _, step in ipairs(spring or {}) do
        _after(gm, at, function()
            if obj.REMOVED then return Y end
            _ease(gm, obj, "draw_offset_x", normal.x + (step.x or 0), step.t, step.ease, queue)
            return _ease(gm, obj, "draw_offset_y", normal.y + (step.y or 0), step.t, step.ease, queue)
        end, queue)
        at = at + (step.t or 0)
    end

    _after(gm, at + 0.04, function() return M.restore_draw_offset(obj, key) end, queue)
    return at + 0.04
end

return M
