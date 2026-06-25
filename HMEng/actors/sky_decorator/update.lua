local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init")

local abs, sin, pi = math.abs, math.sin, math.pi
local min, max = math.min, math.max
local floor = math.floor

local Y = true

return function (SkyDecorator)
--------------------------------------------------
--- Helpers
--------------------------------------------------
--- Helper: clamp
local function _clamp(v, lo, hi) return max(lo, min(hi, v or 0)) end

--- Helper: lerp
local function _lerp(a, b, t) return (a or 0) + ((b or 0) - (a or 0))*t end

--- Helper: ease in-out
local function _ease_in_out(t) return t*t*(3 - 2*t) end

--- Helper: curve 01
local function _curve01(curve, phase)
    if curve == "ramp" then return phase end
    if curve == "pulse" then return phase < 0.5 and phase*2 or 0 end
    return sin(pi*phase)
end

--------------------------------------------------
--- flyover motion
--------------------------------------------------
function SkyDecorator:_apply_flyover_pos(t)
    local fly = self.flyover or {}
    local start, finish = fly.start or {}, fly.finish or fly["end"] or {}
    local T, VT = self.T, self.VT
    local et = fly.ease == "smooth" and _ease_in_out(t) or t

    local x = _lerp(start.x, finish.x, et)
    local y = _lerp(start.y, finish.y, et) + (fly.arc_y or 0)*sin(pi*t) + (fly.wave_y or 0)*sin((fly.wave_freq or 2)*pi*t + (fly.phase or 0))
    local s = _lerp(start.scale or fly.scale or T.scale or 1, finish.scale or fly.scale or T.scale or 1, et)
    local r = _lerp(start.r or fly.r or 0, finish.r or fly.r or 0, et) + (fly.tilt or 0)*sin(pi*t)

    local base_scale = self.base_model_scale or self.model_scale or { x = 1, y = 1 }
    local flip_x = fly.flip_x or 1
    self.model_scale.x, self.model_scale.y = abs(base_scale.x or 1)*(flip_x < 0 and -1 or 1), base_scale.y or 1

    T.x, T.y, T.scale, T.r = x, y, s, r
    VT.x, VT.y, VT.scale, VT.r = x, y, s, r
end

--- Helper: drive one param
local function _drive_param(self, cfg, t, elapsed)
    local v
    if cfg.kind == "progress" then
        v = _lerp(cfg.from or 0, cfg.to or 1, t)
    elseif cfg.kind == "cycle" then
        local cycle = max(cfg.cycle or (1 / max(cfg.speed or 8, 0.001)), 0.001)
        local phase = (elapsed / cycle + (cfg.phase or 0))
        phase = phase - floor(phase)
        local lo, hi = cfg.lo or 0, cfg.hi or 1
        v = _lerp(lo, hi, _curve01(cfg.curve or "sin01", phase))
    else
        v = (cfg.offset or 0) + (cfg.amp or 1)*sin((cfg.speed or 8)*elapsed + (cfg.phase or 0))
    end
    self:set_anim_param(cfg.id, v, cfg.lo, cfg.hi)
end

--- Helper: drive params
local function _drive_params(self, t, elapsed)
    for _, cfg in ipairs(self.param_drivers or {}) do if cfg.id then _drive_param(self, cfg, t, elapsed) end end
end

--------------------------------------------------
--- move
--------------------------------------------------
function SkyDecorator:move(dt)
    local fly = self.flyover or {}
    local duration = max(fly.duration or 4.5, 0.001)
    local elapsed = self.elapsed or 0
    local t = _clamp(elapsed / duration, 0, 1)

    self:_apply_flyover_pos(t)
end

--------------------------------------------------
--- update
--------------------------------------------------
function SkyDecorator:update(dt)
    self.elapsed = (self.elapsed or 0) + dt
    local fly = self.flyover or {}
    local duration = max(fly.duration or 4.5, 0.001)
    local t = _clamp(self.elapsed / duration, 0, 1)

    AnimDecorator.update(self, dt)
    _drive_params(self, t, self.elapsed)

    if t >= 1 and self.remove_on_finish then self:remove(); return Y end
end

end
