local push = table.insert
local M = {}

-----------------------------
--- register
----------------------------------
local mods = {
    cycle    = require("HMGplay.run_flow.lifecycle"),
    flow     = require("HMGplay.run_flow.flow"),
    tutorial = require("HMGplay.run_flow.tutorial"),
}

--- Helper: ensure namespace
local function ensure_ns(root, dotted)
    local t = root
    for seg in dotted:gmatch("[^%.]+") do t[seg] = t[seg] or {}; t = t[seg] end
    return t
end

--- Helper: set function
local function set_func(root, dotted, fn, source)
    local parts = {}
    for seg in dotted:gmatch("[^%.]+") do parts[#parts + 1] = seg end
    local last = parts[#parts]
    local tbl  = (#parts > 1) and ensure_ns(root, table.concat(parts, ".", 1, #parts - 1)) or root
    assert(type(tbl[last]) ~= "function", ("Duplicate gm.Fs key: %s (from %s)"):format(dotted, source))
    assert(type(tbl[last]) ~= "table", ("Name conflict (table exists) for %s (from %s)"):format(dotted, source))
    tbl[last] = fn
end

--- Helper: wrap pure
local function wrap_pure(fn)
    return function(a, ...)
        if type(a) == "table" and (a.Fs or a.SET or a.Ver) then return fn(...)
        else return fn(a, ...) end
    end
end

local exports = {
    { to = "init_run",          mod = "flow",     fn = "init_run",          kind = "gm" },
    { to = "transition_to_run", mod = "flow",     fn = "transition_to_run", kind = "gm" },
    { to = "new_run_args",      mod = "flow",     fn = "new_run_args",      kind = "gm" },
    { to = "begin_new_run",     mod = "flow",     fn = "begin_new_run",     kind = "gm" },
    { to = "qui",               mod = "flow",     fn = "quit",             kind = "pure" },
    { to = "victory",           mod = "cycle",    fn = "victory",          kind = "gm" },
    { to = "tut_test",          mod = "tutorial", fn = "tut_test",         kind = "gm" },
}

function M.register(gm)
    gm.Fs = gm.Fs or {}
    for _, e in ipairs(exports) do
        local source = ("run.%s.%s"):format(e.mod, e.fn)
        local modtbl = assert(mods[e.mod], ("Missing module '%s'"):format(e.mod))
        local fn     = assert(modtbl[e.fn], ("Missing fn %s in module %s"):format(e.fn, e.mod))
        local out_fn = (e.kind == "pure") and wrap_pure(fn) or fn
        set_func(gm.Fs, e.to, out_fn, source)
    end
end

return M
