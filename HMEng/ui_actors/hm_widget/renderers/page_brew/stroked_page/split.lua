local M = {}

---____________________________
--- main: regions
---______________________________________
function M.regions(gm, split)
    if not split then return end

    local RT      = gm._room.T
    local Rw, Rh  = RT.w,           RT.h
    local x,  y   = split.x or 0.,  split.y or 0.
    local r       = split.r

    local region  = split.region or {}
    local axis    = region.axis

    local rot_offset, oy_base  = region["or"] or 0,  region.oy_base
    local ox,         oy       = region.ox or 0,     region.oy or 0

    if axis == "horizontal" then
        local region_w = 1.4*Rh
        return {
            { px = x, py = y, ox = ox, oy = oy, oy_base = oy_base, x = -region_w, y = -1, w = region_w, h = 2, r = r + rot_offset, side = -1 },
            { px = x, py = y, ox = ox, oy = oy, oy_base = oy_base, x =         0, y = -1, w = region_w, h = 2, r = r + rot_offset, side =  1 },
        }
    end

    local region_h = 1.4*Rw
    return {
        { px = x, py = y, ox = ox, oy = oy, oy_base = oy_base, x = -1, y = -region_h, w = 2, h = region_h, r = r + rot_offset, side = -1 },
        { px = x, py = y, ox = ox, oy = oy, oy_base = oy_base, x = -1, y =         0, w = 2, h = region_h, r = r + rot_offset, side =  1 },
    }
end

---____________________________
--- main: strokes
---______________________________________
function M.strokes(split)
    if not split then return end
    local stroke = split.stroke;        if not stroke then return end
    local out = {}
    for k, v in pairs(stroke) do out[k] = v end

    out.x,  out.y      = split.x or 0., split.y or 0.
    out.r,  out.scale  = split.r or 0,   out.scale or 1
    out.ox, out.oy     = out.ox or 0,    out.oy or 0

    return (out.stroke_key or out.key or out.quad_key) and { out }
end

---____________________________
--- main: sync_strokes
---______________________________________
function M.sync_strokes(widget)
    local split   = widget.config.split;          if not split then return end
    local stroke  = split.stroke;                 if not stroke then return end
    local sprites = widget.page_stroke_sprites;   if not sprites then return end

    for _, sprite in ipairs(sprites) do
        local cfg = sprite.config
        cfg.x,  cfg.y        = split.x or 0,   split.y or 0
        cfg.ox, cfg.oy       = stroke.ox or 0, stroke.oy or 0
        cfg.r,  cfg.oy_base  = split.r or 0,   stroke.oy_base or 0
    end
end

return M
