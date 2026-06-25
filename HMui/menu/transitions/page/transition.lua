local TabUtils     = require("HMfns.utils.table_utils")
local PageAnimator = require("HMui.menu.transitions.page.animator")
local PageTunnel   = require("HMui.menu.transitions.page.tunnel")
local Timeline     = require("HMui.menu.transitions.timeline")

local _copy = TabUtils.deep_copy

local M = {}

local DEFAULT_KIND = "hybrid"

-------------------------------------------------
--- kind helpers
-------------------------------------------------
--- Helper: transition_kind
local function transition_kind(gm, opts)
    opts = opts or {}
    return opts.kind or opts.mode or (gm and gm.page_transition_kind) or (gm and gm.SET and gm.SET.page_transition_kind) or DEFAULT_KIND
end

--- Helper: merged_opts
local function merged_opts(opts, key)
    local out = {}
    for k, v in pairs(opts or {}) do
        if k ~= "animator" and k ~= "tunnel" and k ~= "kind" and k ~= "mode" then out[k] = _copy(v) end
    end
    for k, v in pairs((opts and opts[key]) or {}) do out[k] = _copy(v) end
    return out
end

-------------------------------------------------
--- hybrid helpers
-------------------------------------------------
--- Helper: start_hybrid
local function start_hybrid(gm, opts)
    local animator_opts = merged_opts(opts, "animator")
    local tunnel_opts   = merged_opts(opts, "tunnel")
    local overlap_delay = opts.overlap_delay or Timeline.hybrid.overlap_delay

    if animator_opts.bg_color == nil then animator_opts.bg_color = false end
    if animator_opts.alpha_delay == nil then animator_opts.alpha_delay = overlap_delay end

    tunnel_opts.on_revealed = nil
    tunnel_opts.reveal_roots = {}
    tunnel_opts.on_covered = nil
    tunnel_opts.cover_wipe = false

    local tunnel_trans = PageTunnel.start(gm, tunnel_opts); if not tunnel_trans then return end
    local animator_trans = PageAnimator.start(gm, animator_opts)
    if animator_trans then animator_trans.bg_transition = tunnel_trans end
    return tunnel_trans
end

-------------------------------------------------
--- start
-------------------------------------------------
function M.start(gm, opts)
    opts = opts or {}
    local kind = transition_kind(gm, opts)
    if kind == "animator" then return PageAnimator.start(gm, merged_opts(opts, "animator")) end
    if kind == "hybrid"   then return start_hybrid(gm, opts) end
    return PageTunnel.start(gm, merged_opts(opts, "tunnel"))
end

return M
