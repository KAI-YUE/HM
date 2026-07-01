local Layout = require("HMui.hud.cfg_data.layout")
local LG     = love.graphics

local N = false

local M = {}

-----------------------------
--- config
-----------------------------
function M.cfg(opts)
    if opts and opts.mask == N then return end
    if type(opts and opts.mask) == "table" then return opts.mask end
    return Layout.profile_mask
end

-----------------------------
--- sub config
----------------------------
--- Helper: sub config
local function _sub_cfg(cfg, sub)
    return {
        atlas_key = sub.atlas_key or cfg.atlas_key,
        quad_key  = sub.quad_key,
        x = sub.x, y = sub.y, w = sub.w, h = sub.h, r = sub.r,
        relative = sub.relative ~= nil and sub.relative or cfg.relative,
        fit_axis = sub.fit_axis or cfg.fit_axis,
        draw = sub.draw, tint = sub.tint,
    }
end

-----------------------------
--- geometry
-----------------------------
function M.box(child, cfg)
    local VT = child and child.VT; if not VT then return end
    if cfg.relative ~= N then return { x = (cfg.x or 0)*VT.w, y = (cfg.y or 0)*VT.h, w = (cfg.w or 1)*VT.w, h = (cfg.h or 1)*VT.h } end
    return { x = cfg.x or 0, y = cfg.y or 0, w = cfg.w or VT.w, h = cfg.h or VT.h }
end

function M.fit_box(box, cfg, quad)
    local _, _, qw, qh = quad:getViewport(); if not (qw and qh and qw > 0 and qh > 0) then return end
    if not cfg.h and cfg.fit_axis == "width" then box.h = box.w*qh/qw end
    return box, qw, qh
end

function M.quad(gm, cfg)
    local atlas = gm and gm.T_atlas and gm.T_atlas[cfg.atlas_key or "icon_pack"]; if not atlas then return end
    local ok, quad = pcall(atlas.get_quad, atlas, cfg.quad_key or "paper-1"); if not ok then return end
    return atlas, quad
end

function M.sub_cfg(cfg, key)
    local sub = cfg and cfg[key]; if type(sub) ~= "table" then return end
    if type(sub[1]) == "table" then return _sub_cfg(cfg, sub[1]) end
    return _sub_cfg(cfg, sub)
end

function M.sub_cfgs(cfg, key)
    local sub, out = cfg and cfg[key], {}; if type(sub) ~= "table" then return out end
    if type(sub[1]) ~= "table" then out[1] = _sub_cfg(cfg, sub); return out end
    for i, s in ipairs(sub) do out[i] = _sub_cfg(cfg, s) end
    return out
end

function M.rect(panel, child, cfg)
    local gm, box = panel and panel.gm, M.box(child, cfg); if not (gm and box) then return end
    local atlas, quad = M.quad(gm, cfg); if not quad then return end
    local qw, qh; box, qw, qh = M.fit_box(box, cfg, quad); if not box then return end
    local tz = child.rcfg.tile_size
    return { x = box.x, y = box.y, w = box.w*tz, h = box.h*tz, box = box, qw = qw, qh = qh, atlas = atlas, quad = quad }
end

-----------------------------
--- draw
-----------------------------
function M.draw(panel, child, cfg)
    local r = M.rect(panel, child, cfg); if not r then return end
    LG.draw(r.atlas.image, r.quad, r.box.x, r.box.y, cfg.r or 0, r.w/r.qw, r.h/r.qh)
end

function M.draw_visible(panel, child, cfg)
    if cfg.draw == N then return end
    local tint = cfg.tint or { 1, 1, 1, 0.42 }
    LG.setColor(tint[1] or 1, tint[2] or 1, tint[3] or 1, tint[4] or 1)
    M.draw(panel, child, cfg)
    LG.setColor(1, 1, 1, 1)
end

function M.draw_visible_sub(panel, child, cfg, key)
    local sub = M.sub_cfg(cfg, key); if not (sub and sub.draw ~= N) then return end
    local tint = sub.tint or cfg.tint or { 1, 1, 1, 0.42 }
    LG.setColor(tint[1] or 1, tint[2] or 1, tint[3] or 1, tint[4] or 1)
    M.draw(panel, child, sub)
    LG.setColor(1, 1, 1, 1)
end

function M.draw_visible_subs(panel, child, cfg, key)
    for _, sub in ipairs(M.sub_cfgs(cfg, key)) do
        if sub.draw ~= N then
            local tint = sub.tint or cfg.tint or { 1, 1, 1, 0.42 }
            LG.setColor(tint[1] or 1, tint[2] or 1, tint[3] or 1, tint[4] or 1)
            M.draw(panel, child, sub)
        end
    end
    LG.setColor(1, 1, 1, 1)
end

return M
