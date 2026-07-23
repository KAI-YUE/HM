local M = {}

local _steps      = 10
local _visual_min = 0.05
local _visual_max = 0.85

-----------------------------
--- clamp01 | range_min | range_max | visual_value
----------------------------------
function M.clamp01(value)       return math.max(0, math.min(value or 0, 1)) end
function M.range_min(args)      return tonumber(args and args.min_val) or 0 end
function M.range_max(args)      return tonumber(args and args.max_val) or _steps end
function M.visual_value(value)  local v = M.clamp01(value); return _visual_min + (_visual_max - _visual_min) * v end

---____________________________
--- main: normalized_value
---______________________________________
function M.normalized_value(args)
    args = args or {}
    if args.min_val == nil and args.max_val == nil then return M.clamp01(args.value) end

    local min_val, max_val = M.range_min(args), M.range_max(args)
    if max_val == min_val then return 0 end
    return M.clamp01(((tonumber(args.value) or min_val) - min_val) / (max_val - min_val))
end

---____________________________
--- main: display_value
---______________________________________
function M.display_value(args)
    local min_val,  max_val   = M.range_min(args), M.range_max(args)
    local value,    decimals  = min_val + (max_val - min_val) * M.normalized_value(args), args and args.decimals or 0

    if decimals <= 0 then return tostring(math.floor(value + 0.5)) end
    return string.format("%." .. tostring(decimals) .. "f", value)
end

return M
