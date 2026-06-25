local LG = love.graphics

local M = {}

--------------------------------------
--- draw_alpha | atlas
--------------------------------------
function M.draw_alpha(ctx, alpha) if alpha ~= nil then return alpha end; return (ctx and ctx.draw_alpha) or 1 end
function M.atlas(gm, cfg) return gm and gm.T_atlas and gm.T_atlas[(cfg and cfg.atlas_key) or "icons"] end

----------------------------------------
--- color_alpha
----------------------------------------
function M.color_alpha(color, alpha)
    color = color or { 1, 1, 1, 1 }
    return { color[1], color[2], color[3], (color[4] or 1) * (alpha or 1) }
end

-----------------------------------
--- draw_icon
-----------------------------------
function M.draw_icon(atlas, key, x, y, h, r, color, opts)
    local quad = atlas and atlas:get_quad(key);       if not quad then return end
    local _, _, qw, qh = quad:getViewport()
    local s = h / qh
    opts = opts or {}
    local sx, sy = s*(opts.scale_x or 1), s*(opts.scale_y or 1)
    LG.setColor(color)
    LG.draw(atlas.image, quad, x, y, r, sx, sy, 0.5*qw, 0.5*qh)
end

return M
