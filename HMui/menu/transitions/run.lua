local PageAnimator   = require("HMui.menu.transitions.page.animator")
local PageTransition = require("HMui.menu.transitions.page.transition")
local SnapshotTrans  = require("HMui.menu.transitions.snapshot")
local TabUtils       = require("HMfns.utils.table_utils")

local _copy = TabUtils.deep_copy

local Y = true

local M = {}

-------------------------------------------------
--- Helpers
-------------------------------------------------
local function resolve_run_args(gm, opts)
    local args = opts and opts.run_args
    if type(args) == "function" then return args(gm) end
    if args ~= nil then return args end
    return {}
end

local function enqueue_run_start(gm, args, clear_queue)
    local EM = gm.E_MANAGER
    if clear_queue ~= false then EM:clear_queue() end
    EM:enqueue_event({ no_delete = Y, func = function() return gm:start_run(args) end })
    return Y
end

local function with_reveal_ready(run_args, ready_fn)
    local args = _copy(run_args)
    local on_prepared = args.on_prepared
    args.on_prepared = function(gm)
        if on_prepared then on_prepared(gm) end
        return ready_fn(gm)
    end
    return args
end

-------------------------------------------------
--- Transition modes
-------------------------------------------------
local function start_direct(gm, opts)
    local args = resolve_run_args(gm, opts); if not args then return end
    return enqueue_run_start(gm, args)
end

local function start_page(gm, opts)
    local transition = _copy(opts.transition)
    transition.on_covered = function(_gm)
        local run_args = resolve_run_args(_gm, opts); if not run_args then return end
        local args = with_reveal_ready(run_args, function(__gm) return PageAnimator.ready(__gm) end)
        return enqueue_run_start(_gm, args)
    end
    return PageTransition.start(gm, transition)
end

local function start_snapshot(gm, opts)
    local EM = gm.E_MANAGER
    local duration = opts.duration or 1.58
    local args = resolve_run_args(gm, opts); if not args then return end
    local snapshot = SnapshotTrans.capture(gm, opts.snapshot)

    EM:clear_queue()
    SnapshotTrans.ease_out(gm, snapshot, duration)
    enqueue_run_start(gm, args, false)
    SnapshotTrans.clear_after(gm, duration, opts.on_revealed, snapshot)
    return Y
end

-------------------------------------------------
--- Start run transition
-------------------------------------------------
function M.start(gm, opts)
    opts = opts or {}
    local kind = opts.kind or "direct"
    if kind == "page"     then return start_page(gm, opts) end
    if kind == "snapshot" then return start_snapshot(gm, opts) end
    return start_direct(gm, opts)
end

return M
