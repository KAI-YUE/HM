local Layout = require("HMui.hud.cfg_data.layout")
local Mask   = require("HMui.hud.profile.mask")
local LG     = love.graphics

local floor, max = math.floor, math.max
local N = false

local M = {}

-----------------------------
--- helpers
-----------------------------
--- Helper: hash
local function _hash(n) return (math.sin(n*12.9898 + 78.233)*43758.5453) % 1 end

--- Helper: pick quad
local function _quad(atlas, keys, i)
    local key = keys and keys[((i - 1) % #keys) + 1] or "smudge_1"
    local ok, quad = pcall(atlas.get_quad, atlas, key); if not ok then return end
    return quad, key
end

--- Helper: quad scale
local function _quad_scale(cfg, key)
    local scale = cfg.quad_scale or cfg.smudge_scale
    if type(scale) == "table" then return scale[key] or scale.default or 1 end
    return scale or 1
end

--- Helper: draw one
local function _draw_one(atlas, quad, x, y, w, rot, alpha)
    local _, _, qw, qh = quad:getViewport(); if not (qw and qh and qw > 0) then return end
    local sx = w/qw
    LG.setColor(1, 1, 1, alpha or 1)
    LG.draw(atlas.image, quad, x, y, rot or 0, sx, sx, 0.5*qw, 0.5*qh)
end

--- Helper: grid slot
local function _slot(area, cfg, col, row, cols, rows, i)
    local j = cfg.jitter or {}
    local gap_x, gap_y = cfg.col_gap or cfg.gap_x or 1, cfg.row_gap or cfg.gap_y or 1
    local row_bias = (cfg.row_bias_x or cfg.row_x_bias or 0) * ((row % 2 == 0) and 1 or -1)
    local u = 0.5 + (col - (cols + 1)*0.5)*gap_x/max(cols, 1) + row_bias
    local v = 0.5 + (row - (rows + 1)*0.5)*gap_y/max(rows, 1)
    local jx, jy = (_hash(i) - 0.5)*(j.x or 0)*area.w, (_hash(i + 31) - 0.5)*(j.y or 0)*area.h
    local sc = 1 + (_hash(i + 67) - 0.5)*(j.scale or 0)
    local rot = (_hash(i + 101) - 0.5)*(j.r or 0)
    return area.x + u*area.w + jx, area.y + v*area.h + jy, area.w*(cfg.smudge_w or 0.28)*sc, rot
end

--- Helper: area x
local function _area_x(cfg, VT, tz, w, base)
    if cfg.x_from_right then return VT.w*tz - cfg.x_from_right*(cfg.relative ~= N and VT.w*tz or tz) - w end
    if cfg.x ~= nil then return (cfg.relative ~= N and cfg.x*VT.w*tz or cfg.x*tz) end
    return base.x
end

--- Helper: array area
function M.area(panel, child, cfg)
    local base = Mask.rect(panel, child, Layout.profile_mask); if not base then return end
    if not (cfg.x or cfg.x_from_right or cfg.y or cfg.w or cfg.h) then return base end
    local VT, tz = child.VT, child.rcfg.tile_size
    local rel = cfg.relative ~= N
    local w = cfg.w and (rel and cfg.w*VT.w*tz or cfg.w*tz) or base.w
    local h = cfg.h and (rel and cfg.h*VT.h*tz or cfg.h*tz) or base.h
    return { x = _area_x(cfg, VT, tz, w, base), y = cfg.y ~= nil and (rel and cfg.y*VT.h*tz or cfg.y*tz) or base.y, w = w, h = h }
end

-----------------------------
--- draw
-----------------------------
function M.draw(panel, child, cfg)
    cfg = cfg or Layout.profile_mask and Layout.profile_mask.smudge_array; if not (cfg and cfg.draw ~= N) then return end
    local gm = panel and panel.gm; local atlas = gm and gm.T_atlas and gm.T_atlas[cfg.atlas_key or "hud_pack"]; if not atlas then return end
    local area = M.area(panel, child, cfg); if not area then return end
    local cols, rows = max(1, floor(cfg.cols or 1)), max(1, floor(cfg.rows or 1))
    for row = 1, rows do for col = 1, cols do
        local i = (row - 1)*cols + col
        local quad, key = _quad(atlas, cfg.quad_keys, i)
        if quad then local x, y, w, rot = _slot(area, cfg, col, row, cols, rows, i); _draw_one(atlas, quad, x, y, w*_quad_scale(cfg, key), rot, cfg.alpha or 0.32) end
    end end
    LG.setColor(1, 1, 1, 1)
end

return M
