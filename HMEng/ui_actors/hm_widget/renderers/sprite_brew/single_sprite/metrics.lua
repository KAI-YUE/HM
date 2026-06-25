local M = {}

---____________________________
--- main: quad_metrics
---______________________________________
function M.quad_metrics(quad) local _, _, w, h = quad:getViewport(); return { w = w, h = h } end

---____________________________
--- main: layout_sprite
---______________________________________
function M.layout_sprite(self, metrics)
    local rcfg, cfg  = self.rcfg,     self.config
    local VT,   tz   = self.VT,       rcfg.tile_size
    local wpx,  hpx  = VT.w*tz,       VT.h*tz
    local sx,   sy   = wpx/metrics.w, hpx/metrics.h
    local dw,   dh   = metrics.w*sx,  metrics.h*sy
    local ofs        = cfg.sprite_offset or { x = 0, y = 0 }
    local x,  y      = 0.5*(wpx - dw) + (ofs.x or 0)*wpx, 0.5*(hpx - dh) + (ofs.y or 0)*hpx
    return x, y, sx, sy, wpx, hpx
end

return M
