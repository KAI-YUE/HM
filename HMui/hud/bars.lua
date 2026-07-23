local C      = require("HMfns.animate.color.color_const")

local LG       = love.graphics
local min, max = math.min, math.max

local cw = C.WHITE

local M = {}

--- Helpers: stat pair | clamp | cap metrics | fit cap 
local function _stat_pair(stats, key)      if key == "hp" then return stats.hp or 0, stats.hp_max or 1 end; return stats.full or 0, stats.full_max or 1; end
local function _clamp(v, min_v, max_v)     return max(min_v, min(max_v, v)) end
local function _cap_metrics(atlas, key)    local q = atlas and atlas.quads and atlas.quads[key]; if not q then return end; local _, _, w, h = q:getViewport(); return q, w, h end
local function _fit_cap_w(bar, atlas, key) local _, qw, qh = _cap_metrics(atlas, key); if bar.fit_axis == "height" and qw and qh and qh > 0 then return bar.h*qw/qh end; return bar.cap_w or bar.h end
local function _body_w(bar)                if bar.body_w then return bar.body_w end; return bar.w or 2.5 end
local function _body_h(bar)                return bar.body_h or bar.h end
local function _body_y(bar)                return bar.y + 0.5*(bar.h - _body_h(bar)) end
local function _overlap(bar)               return bar.cap_overlap or 0 end

-- Helper: draw cap
local function _draw_cap(atlas, key, x, y, w, h, color) 
    local q, qw, qh = _cap_metrics(atlas, key); if not q then return end; 
    LG.setColor(color or cw)
    LG.draw(atlas.image, q, x, y, 0, w/qw, h/qh) 
end

-----------------------------
--- bars
----------------------------
function M.hud_bar(cfg) return { key = cfg.key, x = cfg.x, y = cfg.y, w = cfg.w, body_w = cfg.body_w, body_h = cfg.body_h, h = cfg.h, cap_w = cfg.cap_w, cap_overlap = cfg.cap_overlap, pad = cfg.pad, fit_axis = cfg.fit_axis, atlas_key = cfg.atlas_key or "hud_pack", left_key = cfg.left_key or "hud_bar_left", right_key = cfg.right_key or "hud_bar_right", style = cfg.style or cfg } end

--- Helper: draw bar frame
local function _draw_bar_frame(bar, style, atlas)
    local body_w, body_h, overlap = _body_w(bar), _body_h(bar), _overlap(bar)
    LG.setColor(style.body or style.fill or style.bg or { 0.08, 0.07, 0.06, 0.72 })
    LG.rectangle("fill", bar.x - overlap, _body_y(bar), body_w + 2*overlap, body_h, 0.04, 0.04)
end

--- Helper: draw bar caps
local function _draw_bar_caps(bar, style, atlas)
    local left_w, right_w = _fit_cap_w(bar, atlas, bar.left_key), _fit_cap_w(bar, atlas, bar.right_key)
    local body_w = _body_w(bar)
    local cap = style.cap or style.fill or style.body
    _draw_cap(atlas, bar.left_key,  bar.x - left_w, bar.y, left_w,  bar.h, cap)
    _draw_cap(atlas, bar.right_key, bar.x + body_w, bar.y, right_w, bar.h, cap)
end

--- Helper: draw bar
local function _draw_bar(panel, bar, stats)
    local val, max_v = _stat_pair(stats, bar.key)
    local pct, style = _clamp((val or 0) / max(max_v or 1, 1), 0, 1), bar.style or {}
    local atlas = panel.gm and panel.gm.T_atlas and panel.gm.T_atlas[bar.atlas_key]
    local pad, body_w, body_h = bar.pad or 0.04, _body_w(bar), _body_h(bar)
    local fill_x, fill_w = bar.x + pad, (body_w - 2*pad)*pct

    _draw_bar_frame(bar, style, atlas)
    LG.setColor(style.fill or cw);                LG.rectangle("fill", fill_x, _body_y(bar) + pad, fill_w, body_h - 2*pad, 0.04, 0.04)
    _draw_bar_caps(bar, style, atlas)
    LG.setColor(style.line or style.fill or { 1, 1, 1, 0.18 }); LG.rectangle("line", bar.x, _body_y(bar), body_w, body_h, 0.04, 0.04)
end

---______________________________
--- main: attach draw
---______________________________
function M.attach_draw(panel)
    local base_draw = panel.draw
    panel.draw = function(self)
        if base_draw then base_draw(self) end
        if not (self.states.visible and self.hud_stats) then return end
        local norm, T = self.rcfg.tile_scale*self.rcfg.tile_size, self.T
        
        LG.push();                  LG.scale(norm)
        LG.translate(T.x, T.y);     LG.setLineWidth(0.025)
        
        for _, bar in ipairs(self.hud_bars or {}) do _draw_bar(self, bar, self.hud_stats) end
        LG.setColor(1, 1, 1, 1);    LG.pop()
    end
end

return M
