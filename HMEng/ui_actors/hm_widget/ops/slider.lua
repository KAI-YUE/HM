local abs, cos, sin = math.abs, math.cos, math.sin

local Y, N = true, false

local M = {}

-----------------------------
--- math helpers
----------------------------------
local function clamp(value, low, high)   return math.max(low, math.min(value, high)) end
local function quantize01(value, steps)  if not steps or steps <= 0 then return value end; return math.floor(value * steps + 0.5) / steps end

-----------------------------
--- slider helpers
----------------------------------
local function slider_value_text(self, value)
    local cfg = self.config.slider_drag;         if not cfg or not cfg.value_text_id or not self.parent then return end

    local min_val,   max_val   = cfg.min_val or 0, cfg.max_val or (cfg.steps or 10)
    local out_value, decimals  = min_val + (max_val - min_val)*value, cfg.decimals or 0
    local text                 = decimals <= 0 and tostring(math.floor(out_value + 0.5)) or string.format("%." .. tostring(decimals) .. "f", out_value)

    for _, child in ipairs(self.parent.children or {}) do if child.config and child.config.id == cfg.value_text_id then child.config.text = text; return end end
end

--- Helper: sync_role_offset
local function sync_role_offset(self)
    local role = self.role;        if not (role and role.major and role.offset) then return end

    local major_tab       = role.major:get_major()
    local major, moffset  = major_tab.major, major_tab.offset or {}
    local T,   mT,   mVT  = self.T, major.T, major.VT
    local dx,    dy       = T.x - mT.x, T.y - mT.y

    if abs(mVT.r or 0) >= 1e-4 then
        local dw, dh  = -T.w/2 + mT.w/2,           -T.h/2 + mT.h/2
        local c,  s   = cos(mVT.r),                sin(mVT.r)
        local ox, oy  = (dx - dw)*c + (dy - dh)*s, -(dx - dw)*s + (dy - dh)*c
        dx, dy        = ox + dw, oy + dh
    end

    role.offset.x, role.offset.y = dx - (moffset.x or 0), dy - (moffset.y or 0)
end

--- Helper: slider_track_bounds
local function slider_track_bounds(cfg, T)
    if cfg.x1 or cfg.y1 or cfg.x2 or cfg.y2 then return cfg.x1 or T.x, cfg.y1 or T.y, cfg.x2 or cfg.x1 or T.x, cfg.y2 or cfg.y1 or T.y end
    return cfg.drag_min_x or T.x, cfg.drag_y or T.y, cfg.drag_max_x or T.x, cfg.drag_y or T.y
end

--- Helper: slider_drag_init
local function slider_drag_init(self, cfg, T)
    if cfg.drag_min_x then return end

    local ro       = cfg.lock_track and self.role and self.role.offset
    local align_dx = cfg.lock_track and ro and (T.x - (ro.x or 0)) or (cfg.lock_track and 0 or T.x - (cfg.start_x or T.x))
    local align_dy = cfg.lock_track and ro and (T.y - (ro.y or 0)) or (cfg.lock_track and 0 or T.y - (cfg.start_y or T.y))

    cfg.drag_min_x, cfg.drag_max_x  = (cfg.min_x or cfg.x1 or T.x) + align_dx, (cfg.max_x or cfg.x2 or T.x) + align_dx
    cfg.drag_y                      = cfg.y and (cfg.y + align_dy) or ((cfg.y1 or T.y) + align_dy)
    if cfg.x1 or cfg.y1 or cfg.x2 or cfg.y2 then
        cfg.x1, cfg.y1 = (cfg.x1 or T.x) + align_dx, (cfg.y1 or T.y) + align_dy
        cfg.x2, cfg.y2 = (cfg.x2 or cfg.x1 or T.x) + align_dx, (cfg.y2 or cfg.y1 or T.y) + align_dy
    end
end

--- Helper: track_value
local function track_value(T, x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local len2   = dx*dx + dy*dy;                if len2 <= 0 then return 0 end
    return clamp(((T.x - x1)*dx + (T.y - y1)*dy) / len2, 0, 1)
end

--- Helper: nudge_value
local function nudge_value(value, delta, steps)
    if not steps or steps <= 0 then return quantize01(clamp(value + (delta or 0), 0, 1), steps) end
    local dir = (delta or 0) < 0 and -1 or 1
    local n = math.max(1, math.floor(math.abs(delta or 0)*steps + 0.5))
    local idx = math.floor(value*steps + 0.5)
    return clamp(idx + dir*n, 0, steps) / steps
end

-----------------------------
--- public api
----------------------------------
function M.nudge_by_percent(self, delta)
    local cfg = self and self.config and self.config.slider_drag;     if not cfg then return N end
    local T = self.T;                                                 if not T then return N end

    slider_drag_init(self, cfg, T)

    local x1, y1, x2, y2 = slider_track_bounds(cfg, T)
    local value          = nudge_value(track_value(T, x1, y1, x2, y2), delta, cfg.steps)

    T.x, T.y = x1 + (x2 - x1)*value, y1 + (y2 - y1)*value
    sync_role_offset(self)
    self.new_align = Y
    slider_value_text(self, value)
    if cfg.on_change then cfg.on_change(self.gm, self, value) end
    return Y
end

return M
