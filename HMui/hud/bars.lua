local C      = require("HMfns.animate.color.color_const")
local Theme  = require("HMui.hud.cfg_data.theme")

local LG       = love.graphics
local min, max = math.min, math.max

local cw = C.WHITE

local M = {}

local BARS = Theme.bars or {}

--- Helpers: stat pair | clamp
local function _stat_pair(stats, key)  if key == "hp" then return stats.hp or 0, stats.hp_max or 1 end; return stats.full or 0, stats.full_max or 1; end
local function _clamp(v, min_v, max_v) return max(min_v, min(max_v, v)) end

-----------------------------
--- bars
----------------------------
function M.hud_bar(cfg) return { key = cfg.key, x = cfg.x, y = cfg.y, w = cfg.w, h = cfg.h, style = BARS[cfg.key] or {} } end

--- Helper: draw bar
local function _draw_bar(bar, stats)
    local val, max_v = _stat_pair(stats, bar.key)
    local pct, style = _clamp((val or 0) / max(max_v or 1, 1), 0, 1), bar.style or {}

    LG.setColor(style.bg or { 0.08, 0.07, 0.06, 0.72 });  LG.rectangle("fill", bar.x, bar.y, bar.w, bar.h, 0.08, 0.08)
    LG.setColor(style.fill or cw);                        LG.rectangle("fill", bar.x + 0.04, bar.y + 0.05, (bar.w - 0.08)*pct, bar.h - 0.10, 0.06, 0.06)
    LG.setColor(style.line or { 1, 1, 1, 0.18 });         LG.rectangle("line", bar.x, bar.y, bar.w, bar.h, 0.08, 0.08)
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
        LG.push()
        LG.scale(norm)
        LG.translate(T.x, T.y)
        LG.setLineWidth(0.025)
        for _, bar in ipairs(self.hud_bars or {}) do _draw_bar(bar, self.hud_stats) end
        LG.setColor(1, 1, 1, 1)
        LG.pop()
    end
end

return M
