local C, LG = require("HMfns.animate.color.color_const"), love.graphics

local sin, cos, floor, min, max = math.sin, math.cos, math.floor, math.min, math.max
local cw = C.WHITE

local Y, N = true, false

return function (Wallpaper)
--------------------------------------------------
--- drift
--------------------------------------------------
--- Helper: _drift_cfg | _clamp | _smoothstep | _scan_coord | _scan_hash
local function _drift_cfg(self)   local cfg = self.config; return cfg and (cfg.drift or cfg.parallax); end
local function _clamp(v, lo, hi)  return min(max(v, lo), hi) end
local function _smoothstep(t)     t = _clamp(t, 0, 1); return t*t*(3 - 2*t) end
local function _scan_coord(i, n)  if n <= 1 then return 0 end; return (i/(n - 1))*2 - 1 end
local function _scan_hash(n)      return (sin(n*12.9898)*43758.5453)%1 end

--- Helper: _layer_val
local function _layer_val(layer, cfg, key, fallback)
    local v = layer and layer[key]; if v ~= nil then return v end
    v = cfg and cfg[key];           if v ~= nil then return v end
    return fallback
end

--- Helper: _drift_mouse
local function _drift_mouse(self)
    local Ctrl, gm  = self.Ctrl, self.gm
    local cpos      = Ctrl and Ctrl.cursor_position
    local rw, rh    = LG.getDimensions()

    if cpos and rw > 0 and rh > 0 then return (cpos.x/rw - 0.5)*2.0, (cpos.y/rh - 0.5)*2.0 end

    local now = (gm._T.real_s) or 0
    return sin(now * 0.11), cos(now * 0.09)
end

--- Helper: _scan_target
local function _scan_target(st, seed)
    local roll    = _scan_hash(seed + st.col*17 + st.row*31 + st.step*43)
    local dir     = st.dir or 1
    local dc, dr  = dir, 0

    if     roll > 0.84 then dc, dr = 0,   roll > 0.92 and 1 or -1
    elseif roll > 0.66 then dc, dr = dir, roll > 0.75 and 1 or -1 end

    if st.col + dc < 0 or st.col + dc >= st.cols then dc, dr, st.dir = 0, 1, -dir end
    if st.row + dr < 0 or st.row + dr >= st.rows then dr = -dr end
    if dc == 0 and dr == 0 then dc = st.dir end

    return _clamp(st.col + dc, 0, st.cols - 1), _clamp(st.row + dr, 0, st.rows - 1)
end

--- Helper: _scan_advance
local function _scan_advance(st, now, seed)
    st.col,      st.row        = st.to_col,  st.to_row
    st.from_col, st.from_row   = st.col,      st.row
    st.step,     st.started_at = st.step + 1, now
    st.to_col,   st.to_row     = _scan_target(st, seed)
end

--- Helper: _drift_scan
local function _drift_scan(self, cfg, now)
    local cols       = max(2, floor(cfg.scan_cols or 9))
    local rows       = max(2, floor(cfg.scan_rows or 5))
    local step_time  = max(cfg.scan_step_time or 1.8, 0.1)
    local seed       = (self.ID or 1)*13.7 + (cfg.scan_seed or 0)
    local st         = self.drift_scan or self.parallax_scan

    if not st or st.cols ~= cols or st.rows ~= rows then
        local col, row = floor((cols - 1)*0.5), floor((rows - 1)*0.5)
        st = { cols = cols, rows = rows, col = col, row = row, from_col = col, from_row = row, to_col = col + 1, to_row = row, dir = 1, started_at = now, step = 1 }
        st.to_col, st.to_row  = _scan_target(st, seed)
        self.drift_scan       = st
        self.parallax_scan    = nil
    end

    while now - st.started_at >= step_time do _scan_advance(st, now, seed) end

    local q = _smoothstep((now - st.started_at)/step_time)
    local x = _scan_coord(st.from_col, cols)*(1 - q) + _scan_coord(st.to_col, cols)*q
    local y = _scan_coord(st.from_row, rows)*(1 - q) + _scan_coord(st.to_row, rows)*q
    return x, y
end

--- Helper: _drift_focus
local function _drift_focus(self, cfg, now)
    local mode = cfg.mode or cfg.input or "mouse"
    if mode == "scan" or mode == "walk"  then return _drift_scan(self, cfg, now) end
    if mode == "idle" or mode == "drift" then return sin(now * 0.11), cos(now * 0.09) end
    return _drift_mouse(self)
end

--- Helper: _drift_offset
local function _drift_offset(self, layer)
    local cfg = _drift_cfg(self)
    if not self:drift_enabled() then
        local color       = self.config.color or cw
        local draw_alpha  = self.draw_alpha or 1
        if draw_alpha ~= 1.0 then color = { color[1], color[2], color[3], (color[4] or 1) * draw_alpha } end
        return 0, 0, 1, color
    end

    local now         = (self._T.real_s) or 0
    local mx, my      = _drift_focus(self, cfg, now)
    local amount      = _layer_val(layer, cfg, "amount", 0.16)
    local drift       = _layer_val(layer, cfg, "drift",  0.06)
    local speed       = _layer_val(layer, cfg, "speed",  0.16)
    local phase       = _layer_val(layer, cfg, "phase",  self.ID or 0)
    local scale       = _layer_val(layer, cfg, "scale",  1.035)
    local alpha       = _layer_val(layer, cfg, "alpha",  1.0)
    local color       = layer and layer.color or self.config.color or cw
    local draw_alpha  = self.draw_alpha or 1

    local ox = -mx*amount + sin(now*speed + phase)*drift
    local oy = -my*amount*0.55 + cos(now*speed*0.73 + phase)*drift*0.55

    if alpha ~= 1.0       then color = { color[1], color[2], color[3], (color[4] or 1)*alpha } end
    if draw_alpha ~= 1.0  then color = { color[1], color[2], color[3], (color[4] or 1)*draw_alpha } end
    return ox, oy, scale, color
end

---________________________________
--- main: draw wallpaper layer
---________________________________
function Wallpaper:draw_wallpaper_layer(qw, qh, w, h, layer)
    local ox, oy, scale, color = _drift_offset(self, layer)
    LG.setColor(color)
    LG.draw(self.image, self.quad, 0.5*w + ox, 0.5*h + oy, 0, w*scale/qw, h*scale/qh, 0.5*qw, 0.5*qh)
end

-------------------------------------------
--- parallax_enabled | drift enabled
-------------------------------------------
function Wallpaper:drift_enabled()    local cfg = _drift_cfg(self); return cfg and cfg.enabled ~= N end
function Wallpaper:parallax_enabled() return self:drift_enabled() end

end
