local abs, max, min = math.abs, math.max, math.min

local M = {}

-----------------------------
--- scalar helpers
----------------------------
function M.clamp01(v) return max(0, min(1, v or 0)) end
function M.lerp(a, b, t) return a + (b - a)*t end

-----------------------------
--- quad helpers
----------------------------
function M.quad_center(quad)
    local x, y = 0, 0
    for i = 1, 4 do x, y = x + quad[i].x, y + quad[i].y end
    return { x = 0.25*x, y = 0.25*y }
end

function M.translate_quad(quad, dx, dy)
    return { { x = quad[1].x + dx, y = quad[1].y + dy }, { x = quad[2].x + dx, y = quad[2].y + dy }, { x = quad[3].x + dx, y = quad[3].y + dy }, { x = quad[4].x + dx, y = quad[4].y + dy } }
end

function M.lerp_quad(a, b, t)
    return { { x = M.lerp(a[1].x, b[1].x, t), y = M.lerp(a[1].y, b[1].y, t) }, { x = M.lerp(a[2].x, b[2].x, t), y = M.lerp(a[2].y, b[2].y, t) }, { x = M.lerp(a[3].x, b[3].x, t), y = M.lerp(a[3].y, b[3].y, t) }, { x = M.lerp(a[4].x, b[4].x, t), y = M.lerp(a[4].y, b[4].y, t) } }
end

function M.local_quad(quad, T)
    local ox, oy = (T and T.x) or 0, (T and T.y) or 0
    return { { x = quad[1].x - ox, y = quad[1].y - oy }, { x = quad[2].x - ox, y = quad[2].y - oy }, { x = quad[3].x - ox, y = quad[3].y - oy }, { x = quad[4].x - ox, y = quad[4].y - oy } }
end

function M.world_quad(quad, T)
    local ox, oy = (T and T.x) or 0, (T and T.y) or 0
    return { { x = quad[1].x + ox, y = quad[1].y + oy }, { x = quad[2].x + ox, y = quad[2].y + oy }, { x = quad[3].x + ox, y = quad[3].y + oy }, { x = quad[4].x + ox, y = quad[4].y + oy } }
end

function M.quad_delta(a, b)
    local d = 0
    for i = 1, 4 do d = max(d, abs(a[i].x - b[i].x), abs(a[i].y - b[i].y)) end
    return d
end

-----------------------------
--- actor helpers
----------------------------
function M.actor_parallax(actor) return actor and (actor.layered_parallax or (actor.parent and actor.parent.layered_parallax)) or { x = 0, y = 0 } end

return M
