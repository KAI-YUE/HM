local Y, N = true, false

local M = {}

---------------------------------------------
--- after
---------------------------------------------
function M.after(gm, delay, fn, queue)
    local EM = gm and gm.E_MANAGER;    if not EM then return fn() end
    if (delay or 0) <= 0 then return fn() end
    EM:enqueue_event({ queue = queue, trigger = "after", delay = delay, blockable = N, blocking = N, func = fn })
end

---------------------------------------------
--- ease
---------------------------------------------
function M.ease(gm, tab, key, to, delay, ease, queue)
    local EM = gm and gm.E_MANAGER;    if not EM then tab[key] = to; return Y end
    EM:enqueue_event({ queue = queue, trigger = "ease", ease = ease or "lerp", blockable = N, blocking = N, ref_table = tab, ref_value = key, ease_to = to, delay = delay })
    return Y
end

return M
