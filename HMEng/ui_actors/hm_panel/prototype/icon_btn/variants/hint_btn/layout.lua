local Common = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.variants.hint_btn.common")

local _hint_r, _with  = Common.hint_r, Common.with

local Cfg    = Common.cfg()

local M = {}

--- Helper: glyph layout config
local function _glyph_cfg(args)
    local out, key = _with({}, Cfg.glyph.T), args.hint_icon_quad_key or Cfg.glyph.quad_key
    _with(out, Cfg.glyph.T_by_quad and Cfg.glyph.T_by_quad[key])
    return _with(out, args.glyph_T)
end

-----------------------------
--- label
-----------------------------
function M.label_T(args)
    if args.label_T then return args.label_T end
    if args.label_on_btn then local btn = M.base_T(args); return { x = args.label_x or btn.x, y = args.label_y or btn.y, w = args.label_w or args.button_w or btn.w, h = args.label_h or Cfg.label.h, r = _hint_r(args) } end
    if not (args.label_on_glyph or args.label_on_icon) then return { x = args.label_x or Cfg.label.x, y = args.label_y or Cfg.label.y, w = args.label_w or Cfg.label.w, h = args.label_h or Cfg.label.h, r = _hint_r(args) } end
    
    local glyph = _glyph_cfg(args)
    local x, y, w = args.icon_x or glyph.x, args.icon_y or glyph.y, args.icon_w or glyph.w
    return { x = args.label_x or x, y = args.label_y or y, w = args.label_w or w, h = args.label_h or Cfg.label.h, r = _hint_r(args) }
end

-----------------------------
--- mask_quad_cfg
-----------------------------
function M.mask_quad_cfg(args, key)
    local cfg = _with({}, Cfg.mask_underlay)
    _with(cfg, Cfg.mask_by_quad and Cfg.mask_by_quad[key])
    _with(cfg, args.hint_mask_cfg)
    _with(cfg, args.hint_mask_map and args.hint_mask_map[key])
    return cfg
end

-----------------------------
--- mask_quad_key
-----------------------------
function M.mask_quad_key(args, cfg, key)
    local map_item = args.hint_mask_map and args.hint_mask_map[key]

    if type(map_item) == "string" then return map_item end
    if args.hint_mask_quad_key    then return args.hint_mask_quad_key end
    if cfg.quad_key               then return cfg.quad_key end
    if cfg.auto_suffix and key    then return key .. (cfg.suffix or "_mask") end
end

-----------------------------
--- mask_T
-----------------------------
function M.mask_T(args, base_T, cfg)
    local x, y       = args.mask_x or (cfg.x or 0), args.mask_y or (cfg.y or 0)
    local w, w_pad   = args.mask_w or (cfg.w or base_T.w), args.mask_w_pad or (cfg.w_pad or 0)
    local h, h_pad   = args.mask_h or (cfg.h or base_T.h), args.mask_h_pad or (cfg.h_pad or 0)
    local out        = { x = base_T.x + x, y = base_T.y + y, w = (args.button_w or w) + w_pad, r = _hint_r(args), scale = base_T.scale }
    
    if h                                 then out.h = h + h_pad end
    if cfg.wh_ratio                      then out.h = out.w/(cfg.wh_ratio or 1) end
    return out
end

-----------------------------
--- button and glyph
-----------------------------
function M.base_T(args) local T = _with(_with({}, Cfg.btn.T), args.base_T); return { x = args.base_x or T.x, y = args.base_y or T.y, w = args.base_w or T.w, r = _hint_r(args) } end

function M.btn_T(args, base_T, cfg)
    cfg = cfg or {}
    local x, y       = args.btn_x or (cfg.x or 0), args.btn_y or (cfg.y or 0)
    local w, w_pad   = args.btn_w or (cfg.w or base_T.w), args.btn_w_pad or (cfg.w_pad or 0)
    local h, h_pad   = args.btn_h or (cfg.h or base_T.h), args.btn_h_pad or (cfg.h_pad or 0)
    local out        = { x = base_T.x + x, y = base_T.y + y, w = (args.button_w or w) + w_pad, r = _hint_r(args), scale = base_T.scale }
    if h                                then out.h = h + h_pad end
    if cfg.wh_ratio                     then out.h = out.w/(cfg.wh_ratio or 1) end
    return out
end

function M.glyph_keys(args)  return args.hint_icon_quad_keys or (args.hint_icon_quad_key and { args.hint_icon_quad_key }) or { Cfg.glyph.quad_key } end
function M.glyph_T(args, i)
    local glyph      = _glyph_cfg(args)
    local iw, gap    = args.icon_w or glyph.w, args.glyph_gap or args.icon_gap or 0
    local x0, y      = args.icon_x or glyph.x, args.icon_y or glyph.y
    return { x = x0 + (i - 1)*(iw + gap), y = y, w = iw, r = _hint_r(args) }
end

return M
