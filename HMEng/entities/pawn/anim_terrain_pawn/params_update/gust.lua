local LM = love.math

local sin      = math.sin
local min, max = math.min, math.max
local TAU      = 2 * math.pi

--- Helpers: _rand | _clamp | _lerp
local function _rand(a, b)       return a + (b - a) * LM.random() end
local function _clamp(v, lo, hi) return max(lo, min(hi, v or 0)) end
local function _lerp(a, b, t)    return a + (b - a) * t end

return function (AnimTerrainPawn)
--------------------------------------------
--- Helper: init gust channel
--------------------------------------------
local function _init_gust_channel(cfg, prefix)
    local key = prefix and (prefix .. "_") or ""
    return {
        gust_t = 0, gust_wait = _rand(cfg[key .. "wait_min"] or 0.9, cfg[key .. "wait_max"] or 2.6), gust_from = 0,
        gust_target = 0, gust_value = 0, gust_travel_t = cfg[key .. "travel_t"] or cfg.travel_t or 0.45, phase = "idle",
        value = cfg.value or 0, velocity = 0,
    }
end

--- Helper: init gust move
local function _init_gust_move(self)
    if self.anim_gust_move then return self.anim_gust_move end

    local cfg = self.anim_gust_cfg or {}
    self.anim_gust_move = {
        wind_t = 0, instance_phase = ((self.ID or 0) * 2.399963229728653) % TAU,
        gust = _init_gust_channel(cfg), primary_gust = _init_gust_channel(cfg, "primary"),
        amp = cfg.amp or 0.18, offset = cfg.offset or 0,
        stiffness = cfg.stiffness or 18, damping = cfg.damping or 7.2, shove = 0,
    }
    return self.anim_gust_move
end

--- Helper: start gust
local function _start_gust(channel, cfg, prefix)
    local key = prefix and (prefix .. "_") or ""
    local gust_amp = cfg[key .. "gust_amp"] or cfg.gust_amp or 0.72
    channel.phase, channel.gust_t = "gust", 0
    channel.gust_from = channel.gust_value
    channel.gust_target = _rand(-gust_amp, gust_amp)
    channel.gust_travel_t = _rand(cfg[key .. "travel_min"] or cfg.travel_min or 0.45, cfg[key .. "travel_max"] or cfg.travel_max or 1.10)
        + (cfg[key .. "travel_pad"] or cfg.travel_pad or 0.2)
end

--- Helper: update gust phase
local function _update_gust_phase(channel, cfg, dt, prefix)
    local key = prefix and (prefix .. "_") or ""
    if channel.phase == "idle" then
        channel.gust_wait = channel.gust_wait - dt
        if channel.gust_wait <= 0 then _start_gust(channel, cfg, prefix) end
        return
    end

    channel.gust_t = channel.gust_t + dt
    local t = _clamp(channel.gust_t / max(channel.gust_travel_t, 0.001), 0, 1)
    channel.gust_value = _lerp(channel.gust_from, channel.gust_target, t)
    if t < 1 then return end

    if channel.phase == "gust" then
        channel.phase, channel.gust_t, channel.gust_from = "settle", 0, channel.gust_value
        channel.gust_target = (cfg[key .. "settle_scale"] or cfg.settle_scale or 0.25) * channel.gust_target
        channel.gust_travel_t = _rand(cfg[key .. "settle_min"] or cfg.settle_min or 0.7, cfg[key .. "settle_max"] or cfg.settle_max or 1.8)
    else
        channel.phase, channel.gust_t = "idle", 0
        channel.gust_wait = _rand(cfg[key .. "wait_min"] or 1.1, cfg[key .. "wait_max"] or 2.4)
    end
end

--------------------------------------------
--- Helper: update gust channel spring
--------------------------------------------
local function _update_gust_spring(move, channel, cfg, dt)
    local target = _clamp(move.offset + channel.gust_value + (cfg.shove_scale or 0.35) * move.shove, cfg.lo or -1, cfg.hi or 1)
    local accel = move.stiffness * (target - channel.value) - move.damping * channel.velocity
    channel.velocity = channel.velocity + accel * dt
    channel.value = _clamp(channel.value + channel.velocity * dt, cfg.lo or -1, cfg.hi or 1)
end

--- Helper: apply gust movement
local function _apply_gust_movement(self)
    local cfg, move = self.anim_gust_cfg, _init_gust_move(self)
    if not cfg then return end

    local phase = move.instance_phase
    local base = move.amp * sin((cfg.wind_speed or 0.8) * move.wind_t + phase)
        + (cfg.detail_amp or 0.04) * sin((cfg.detail_speed or 1.9) * move.wind_t + 0.8 + phase)
    local wind = _clamp(move.gust.value + base, cfg.lo or -1, cfg.hi or 1)
    local primary_wind = _clamp(move.primary_gust.value, cfg.lo or -1, cfg.hi or 1)

    if cfg.id then self:set_anim_param(cfg.id, wind, cfg.lo, cfg.hi) end
    for _, p in ipairs(cfg.params or {}) do
        local param_wind = p.primary and primary_wind or wind
        local detail = (p.detail or 0) * sin((p.detail_speed or cfg.detail_speed or 1.9) * move.wind_t + (p.phase or 0) + phase)
        local local_wind = _clamp(param_wind + detail, p.lo or cfg.lo or -1, p.hi or cfg.hi or 1)
        self:set_anim_param(p.id, (p.offset or 0) + local_wind * (p.scale or 1), p.lo or cfg.lo, p.hi or cfg.hi)
    end
end

--------------------------------------------
--- set gust wind offset
--------------------------------------------
function AnimTerrainPawn:set_gust_wind_offset(v)
    local cfg, move = self.anim_gust_cfg or {}, _init_gust_move(self)
    move.offset = _clamp(v, cfg.lo or -1, cfg.hi or 1)
    _apply_gust_movement(self)
end

---------------------------------
--- set gust movement
---------------------------------
function AnimTerrainPawn:set_gust_movement(v)
    local cfg, move = self.anim_gust_cfg or {}, _init_gust_move(self)
    local target = _clamp(v, cfg.lo or -1, cfg.hi or 1)
    for _, channel in ipairs({ move.gust, move.primary_gust }) do
        local delta = target - channel.value
        channel.value = channel.value + 0.2 * delta
        channel.velocity = channel.velocity + 6.5 * delta
    end
    move.shove    = target
    _apply_gust_movement(self)
end

-------------------------------------------
--- clear gust movement
-------------------------------------------
function AnimTerrainPawn:clear_gust_movement()
    local cfg, move = self.anim_gust_cfg or {}, _init_gust_move(self)
    for i, channel in ipairs({ move.gust, move.primary_gust }) do
        local key = i == 2 and "primary_" or ""
        channel.phase, channel.gust_t, channel.gust_value = "idle", 0, 0
        channel.gust_wait = _rand(cfg[key .. "wait_min"] or 0.6, cfg[key .. "wait_max"] or 1.8)
        channel.velocity = 0
    end
    move.shove = 0
end

--------------------------------------
--- update gust movement
--------------------------------------
function AnimTerrainPawn:update_gust_movement(dt)
    local cfg = self.anim_gust_cfg;                 if not cfg then return end
    local move = _init_gust_move(self)
    move.wind_t = move.wind_t + dt

    _update_gust_phase(move.gust, cfg, dt)
    _update_gust_phase(move.primary_gust, cfg, dt, "primary")
    _update_gust_spring(move, move.gust, cfg, dt)
    _update_gust_spring(move, move.primary_gust, cfg, dt)
    move.shove    = _lerp(move.shove, 0, min(1, (cfg.shove_decay or 5.5) * dt))

    _apply_gust_movement(self)
end

end
