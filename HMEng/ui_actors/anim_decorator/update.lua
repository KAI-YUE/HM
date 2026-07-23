local LM = love.math

local sin = math.sin
local min, max = math.min, math.max

--- Helper: _rand | _clamp | _lerp
local function _rand(a, b)        return a + (b - a) * LM.random() end
local function _clamp(v, lo, hi)  return max(lo, min(hi, v or 0)) end
local function _lerp(a, b, t)     return a + (b - a) * t end

return function (AnimDecorator)
--- Helper: _init_gust
local function _init_gust(self)
    if self.anim_gust_move then return self.anim_gust_move end

    local cfg = self.anim_gust_cfg or {}
    self.anim_gust_move = {
        wind_t = 0,       gust_t = 0,      gust_wait = _rand(cfg.wait_min or 0.9, cfg.wait_max or 2.6), gust_from = 0,
        gust_target = 0,  gust_value = 0,  gust_travel_t = cfg.travel_t or 0.45, phase = "idle",
        amp = cfg.amp or 0.18, gust_amp = cfg.gust_amp or 0.72, offset = cfg.offset or 0, value = cfg.value or 0,
        velocity = 0, stiffness = cfg.stiffness or 18, damping = cfg.damping or 7.2, shove = 0,
    }
    return self.anim_gust_move
end

--- Helper: _start_gust
local function _start_gust(move, cfg)
    move.phase, move.gust_t = "gust", 0
    move.gust_from = move.gust_value
    move.gust_target = _rand(-(cfg.gust_amp or move.gust_amp), cfg.gust_amp or move.gust_amp)
    move.gust_travel_t = _rand(cfg.travel_min or 0.45, cfg.travel_max or 1.10) + (cfg.travel_pad or 0.2)
end

--- Helper: _update_idle
local function _update_idle(move, cfg, dt)
    move.gust_wait = move.gust_wait - dt
    if move.gust_wait > 0 then return end
    _start_gust(move, cfg)
end

--- Helper: _update_gust
local function _update_gust(move, cfg, dt)
    move.gust_t = move.gust_t + dt
    local t = _clamp(move.gust_t / max(move.gust_travel_t, 0.001), 0, 1)
    move.gust_value = _lerp(move.gust_from, move.gust_target, t)
    if t < 1 then return end
    move.phase, move.gust_t, move.gust_from = "settle", 0, move.gust_value
    move.gust_target, move.gust_travel_t = (cfg.settle_scale or 0.25) * move.gust_target, _rand(cfg.settle_min or 0.7, cfg.settle_max or 1.8)
end

--- Helper: _update_settle
local function _update_settle(move, cfg, dt)
    move.gust_t = move.gust_t + dt
    local t = _clamp(move.gust_t / max(move.gust_travel_t, 0.001), 0, 1)
    move.gust_value = _lerp(move.gust_from, move.gust_target, t)
    if t < 1 then return end
    move.phase, move.gust_t = "idle", 0
    move.gust_wait = _rand(cfg.wait_min or 1.1, cfg.wait_max or 2.4)
end

--- Helper: _apply_gust
local function _apply_gust(self)
    local cfg, move = self.anim_gust_cfg, _init_gust(self)
    if not (cfg and cfg.id) then return end

    local base = move.amp * sin((cfg.wind_speed or 0.8) * move.wind_t) + (cfg.detail_amp or 0.04) * sin((cfg.detail_speed or 1.9) * move.wind_t + 0.8)
    local v = _clamp(move.value + base, cfg.lo or -1, cfg.hi or 1)
    self:set_anim_param(cfg.id, v)
end

--- Helper: _update_gust_driver
local function _update_gust_driver(self, dt)
    local cfg = self.anim_gust_cfg;       if not cfg then return end
    local move = _init_gust(self)
    move.wind_t = move.wind_t + dt

    if     move.phase == "idle"   then _update_idle(move, cfg, dt)
    elseif move.phase == "gust"   then _update_gust(move, cfg, dt)
    elseif move.phase == "settle" then _update_settle(move, cfg, dt)
    end

    local target = _clamp(move.offset + move.gust_value + (cfg.shove_scale or 0.35) * move.shove, cfg.lo or -1, cfg.hi or 1)
    local accel = move.stiffness * (target - move.value) - move.damping * move.velocity
    move.velocity = move.velocity + accel * dt
    move.value = _clamp(move.value + move.velocity * dt, cfg.lo or -1, cfg.hi or 1)
    move.shove = _lerp(move.shove, 0, min(1, (cfg.shove_decay or 5.5) * dt))

    _apply_gust(self)
end

---____________________________
--- main: update
---______________________________________
function AnimDecorator:update(dt)
    if not self.auto_update or not self.model then return end
    self.model:update(dt)
    _update_gust_driver(self, dt)
end

end
