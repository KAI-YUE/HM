local M = {}

local mods = {
    map_spawn = require("HMfns.map.map_spawn"),
}

local function ensure_ns(root, dotted)
    local t = root
    for seg in dotted:gmatch("[^%.]+") do t[seg] = t[seg] or {}; t = t[seg] end
    return t
end

local function set_func(root, dotted, fn, source)
    local parts = {}
    for seg in dotted:gmatch("[^%.]+") do parts[#parts + 1] = seg end
    local last = parts[#parts]
    local tbl = (#parts > 1) and ensure_ns(root, table.concat(parts, ".", 1, #parts - 1)) or root
    assert(type(tbl[last]) ~= "function", ("Duplicate gm.Fs key: %s (from %s)"):format(dotted, source))
    assert(type(tbl[last]) ~= "table", ("Name conflict (table exists) for %s (from %s)"):format(dotted, source))
    tbl[last] = fn
end

local function wrap_pure(fn)
    return function(a, ...)
        if type(a) == "table" and (a.Fs or a.SET or a.Ver) then return fn(...) end
        return fn(a, ...)
    end
end

local exports = {
    { to = "map.unit",              mod = "map_spawn", fn = "unit",              kind = "gm"   },
    { to = "map.sorted_keys",       mod = "map_spawn", fn = "sorted_keys",       kind = "pure" },
    { to = "map.filter_known_keys", mod = "map_spawn", fn = "filter_known_keys", kind = "pure" },
    { to = "map.pick_weighted_key", mod = "map_spawn", fn = "pick_weighted_key", kind = "gm"   },
    { to = "map.flip_sign",         mod = "map_spawn", fn = "flip_sign",         kind = "gm"   },
}

function M.register(gm)
    gm.Fs = gm.Fs or {}
    for _, e in ipairs(exports) do
        local source = ("map.%s.%s"):format(e.mod, e.fn)
        local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
        local fn = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
        local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
        set_func(gm.Fs, e.to, out_fn, source)
    end
end

return M
