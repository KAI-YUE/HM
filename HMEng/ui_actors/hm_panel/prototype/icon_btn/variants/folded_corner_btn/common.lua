local Type3 = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.folded_btn_type3_cfg")
local Type4 = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.folded_corner_btn.folded_btn_type4_cfg")

local M = {}
local Cfgs = { type3 = Type3, type4 = Type4 }

-----------------------------
--- config helpers
-----------------------------
function M.clone_args(args) local out = {}; for k, v in pairs(args or {}) do out[k] = v end; return out end
function M.cfg(args) return (args and args._folded_cfg) or Cfgs[(args and args.folded_btn_type) or "type3"] or Type3 end
function M.mask_underlay_enabled(args)
    local cfg = M.cfg(args).mask_underlay; if not cfg then return false end
    if args and args.mask_underlay ~= nil then return args.mask_underlay end
    return cfg.enabled ~= false
end
function M.bg_underlay_enabled(args)
    local cfg = M.cfg(args).bg_underlay; if not cfg then return false end
    if args and args.bg_underlay ~= nil then return args.bg_underlay end
    return cfg.enabled ~= false
end
function M.bg_paint_seed_entry(args)
    local bg = M.cfg(args).bg; if not bg then return end
    local seeds, index = bg.paint_seeds or {}, (args and args.bg_paint_seed_index) or bg.paint_seed_index
    return (args and args.bg_paint_seed_entry) or seeds[index]
end

-----------------------------
--- defaults
-----------------------------
function M.with_defaults(args)
    local cfg  = M.cfg(args)
    local out  = M.clone_args(cfg.defaults)

    out.frame  = M.clone_args(args and args.frame)
    for k, v in pairs(args or {}) do
        if k == "frame" then for fk, fv in pairs(v or {}) do out.frame[fk] = fv end
        else out[k] = v end
    end
    out._folded_cfg = cfg
    return out
end

-----------------------------
--- anchored T
-----------------------------
function M.anchor_T(T, args)
    local cfg      = M.cfg(args)
    local args, T  = args or {}, T or {}
    local scale    = args.group_scale or cfg.layout.group_scale

    local cx, cy  = (T.x or 0) + 0.5*(T.w or 0),          (T.y or 0) + 0.5*(T.h or 0)
    local w,  h   = args.w or cfg.layout.min_w*scale,     args.h or cfg.layout.h*scale
    local ax, ay  = args.anchor_x or cfg.layout.anchor_cx*scale, args.anchor_y or cfg.layout.anchor_cy*scale
    local sx, sy  = args.x_shift or 0,                    args.y_shift or 0

    return { x = cx - ax + sx, y = cy - ay + sy, w = w, h = h }
end

function M.anchor_offset_T(T, args)
    T = T or {}
    local aT = M.anchor_T(T, args)
    return { x = aT.x - (T.x or 0), y = aT.y - (T.y or 0) }
end

M.type3_cfg = Type3
M.type4_cfg = Type4

return M
