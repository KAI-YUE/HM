local Layout = require("HMui.hud.cfg_data.layout")
local LG     = love.graphics

local ceil, max, min = math.ceil, math.max, math.min
local Y, N = true, false

local M = {}

-----------------------------
--- restore
-----------------------------
local function _restore_stencil(compare, value) if compare then LG.setStencilTest(compare, value) else LG.setStencilTest() end end
local function _restore_canvas(canvas) if canvas then LG.setCanvas({ canvas, stencil = Y }) else LG.setCanvas() end end

-----------------------------
--- scale
-----------------------------
local function _pad(cfg) local p = cfg.canvas_pad or {}; return p.x or p[1] or 0, p.y or p[2] or p.x or p[1] or 0 end

local function _ref_h(child)
    local cfg, VT, tz = Layout.profile_chara or {}, child.VT, child.rcfg.tile_size
    if cfg.relative ~= N then return (cfg.h or 1)*VT.h*tz end
    return (cfg.h or VT.h)*tz
end

local function _scale(child, cfg)
    if type(cfg.canvas_scale) == "number" then return cfg.canvas_scale end
    local src_h = cfg.source_px_h or cfg.canvas_source_h; if not src_h then return 1 end
    local ref_h = _ref_h(child); if not (ref_h and ref_h > 0) then return 1 end
    return min(cfg.canvas_scale_max or 5, max(cfg.canvas_scale_min or 1, src_h/ref_h))
end

-----------------------------
--- canvas
-----------------------------
local function _ensure(child, cfg)
    local tz, px, py = child.rcfg.tile_size, _pad(cfg)
    local cs = _scale(child, cfg)
    local w, h = ceil((child.VT.w + 2*px)*tz*cs), ceil((child.VT.h + 2*py)*tz*cs); if w <= 0 or h <= 0 then return end
    if not child.hud_profile_canvas or child.hud_profile_canvas_w ~= w or child.hud_profile_canvas_h ~= h then child.hud_profile_canvas, child.hud_profile_canvas_w, child.hud_profile_canvas_h = LG.newCanvas(w, h), w, h end
    child.hud_profile_canvas:setFilter("linear", "linear")
    return child.hud_profile_canvas, px*tz, py*tz, cs
end

function M.render(panel, child, draw_fn, cfg)
    local canvas, ox, oy, cs = _ensure(child, cfg); if not canvas then return end
    local old_canvas, old_shader, old_color = LG.getCanvas(), LG.getShader(), { LG.getColor() }
    local old_compare, old_value = LG.getStencilTest()
    local old_sx, old_sy, old_sw, old_sh = LG.getScissor()
    LG.push(); LG.origin(); LG.setCanvas({ canvas, stencil = Y }); LG.setScissor(); LG.setStencilTest(); LG.clear(0, 0, 0, 0); LG.scale(cs); LG.translate(ox, oy)
    draw_fn(panel, child)
    LG.pop(); _restore_canvas(old_canvas); LG.setScissor(old_sx, old_sy, old_sw, old_sh); _restore_stencil(old_compare, old_value); LG.setShader(old_shader); LG.setColor(old_color[1], old_color[2], old_color[3], old_color[4])
    return canvas, ox, oy, cs
end

return M
