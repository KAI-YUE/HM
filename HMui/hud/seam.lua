local HMWidget = require("HMEng.ui_actors.hm_widget")
local Render   = require("HMfns.systems.render")
local C        = require("HMfns.animate.color.color_const")
local Layout   = require("HMui.hud.layout")
local Theme    = require("HMui.hud.theme")
local Common        = require("HMui.hud.common")

local LG       = love.graphics
local atan, pi = math.atan, math.pi

local N = false

local M = {}

local LAYER = Layout.layer
local PANEL = Theme.panel or {}
local push_draw_trans = Render.push_actor_draw_transform

--- Helpers: atan2 | dash quad
local function _atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return atan(y/x) end
    if x < 0 and y >= 0 then return atan(y/x) + pi end
    if x < 0 then return atan(y/x) - pi end
    return y >= 0 and pi*0.5 or -pi*0.5
end

local function _dash_quad(gm, key)
    local atlas = gm and gm.T_atlas and gm.T_atlas.ui_pack; if not atlas then return end
    local ok, quad = pcall(atlas.get_quad, atlas, key or "dash_1"); if not ok then return end
    return atlas, quad
end

-----------------------------
--- draw seam
----------------------------
--- Helper: draw dash segment
local function _draw_dash_segment(img, quad, x1, y1, x2, y2, scale, gap, phase)
    local dx, dy = x2 - x1, y2 - y1
    local len = (dx*dx + dy*dy)^0.5;                      if len <= 0.0001 then return end
    local _, _, qw, qh = quad:getViewport()
    local step = qw*scale + gap;                          if step <= 0 then return end
    local ux, uy, r = dx/len, dy/len, _atan2(dy, dx)
    local d = -phase
    while d < len do
        if d >= 0 then LG.draw(img, quad, x1 + ux*d, y1 + uy*d, r, scale, scale, 0, qh*0.5) end
        d = d + step
    end
end

--- Helper: draw panel seam
local function _draw_panel_seam(widget, cfg)
    cfg = cfg or Layout.panel_seam or {}
    local points = cfg.points;                           if not (points and #points >= 2) then return end
    local atlas, quad = _dash_quad(widget.gm, cfg.dash); if not quad then return end
    local tz, T = widget.rcfg.tile_size, widget.T
    local wpx, hpx = T.w*tz, T.h*tz
    local scale, gap = cfg.scale or 1, cfg.gap_px or 9
    local _, _, qw = quad:getViewport()
    local step = qw*scale + gap
    local speed = PANEL.seam_animate and (PANEL.seam_speed or 0) or 0
    local now = (widget.gm._T and widget.gm._T.real_s) or 0
    local phase = step > 0 and (now*speed)%step or 0

    LG.setColor(PANEL.seam_tint or C.BLUE)
    for i = 1, #points do
        local a, b = points[i], points[i%#points + 1]
        _draw_dash_segment(atlas.image, quad, a[1]*wpx, a[2]*hpx, b[1]*wpx, b[2]*hpx, scale, gap, phase)
    end
end

-----------------------------
--- seam config
----------------------------
function M.cfg(T, cfg) local out = Common.with({}, cfg or {}); out.x, out.y, out.w, out.h = T.x + (out.x or 0), T.y + (out.y or 0), T.w + (out.w_pad or 0), T.h + (out.h_pad or 0); return out end

---______________________________
--- main: attach
---______________________________
function M.attach(panel, cfg, order)
    cfg = cfg or Layout.panel_seam or {};                 if cfg.enabled == N then return end
    local T = { x = cfg.x or 0, y = cfg.y or 0, w = cfg.w or panel.T.w + (cfg.w_pad or 0), h = cfg.h or panel.T.h + (cfg.h_pad or 0) }
    local child = HMWidget(panel.gm, { style = "empty_container", T = T, can_hover = N, can_collide = N, draw_order = order or LAYER.panel + 2 })
    child.hud_panel_seam_cfg = cfg
    child.parent = panel.widget
    child:set_role({ role_type = "Minor", major = panel.widget, offset = { x = T.x or 0, y = T.y or 0 }, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" })
    child.draw = function(self, opts)
        if not self.states.visible or (opts and opts.shadow_only) then return end
        push_draw_trans(self)
        LG.scale(1/self.rcfg.tile_size)
        _draw_panel_seam(self, self.hud_panel_seam_cfg)
        LG.pop()
    end
    panel.widget.children[#panel.widget.children + 1] = child
end

return M
