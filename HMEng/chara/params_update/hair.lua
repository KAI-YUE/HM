local LM = love.math

local sin      = math.sin
local min, max = math.min, math.max
local Y, N     = true, false

--- Helpers: _rand | _clamp | _lerp 
local function _rand(a, b)       return a + (b - a) * LM.random() end
local function _clamp(v, lo, hi) return max(lo, min(hi, v or 0)) end
local function _lerp(a, b, t)    return a + (b - a) * t end

return function (Chara)
--------------------------------------
--- Helper: init hair move
--------------------------------------
local function _init_hair_move(self)
    if self.hair_move then return self.hair_move end

    local cfg = self.hair_cfg or {}
    --- wind_t:      time accumulator for periodic sway
    --- amp:         main hair sway strength
    --- detail_amp:  small flutter layered on top of the main sway
    --- gust_amp:    peak strength used when a gust event starts
    --- gust_t:      elapsed time inside the current gust/settle phase
    --- gust_wait:   countdown before the next gust starts
    --- gust_from:   starting value for the current gust interpolation
    --- gust_target: target value for the current gust interpolation
    --- gust_value:  current interpolated gust amount applied to hair
    --- phase:       idle -> gust -> settle -> idle
    --- offset:      manual baseline wind bias from the caller
    --- value:       smoothed hair bend after spring-damper filtering
    --- velocity:    how fast the smoothed value is changing
    --- shove:       short-lived push from direct input; decays back to 0
    --- stiffness:   how strongly the spring pulls value toward target
    --- damping:     how strongly velocity is resisted to remove overshoot
    
    local _detail_amp, _gust_amp = cfg.detail_amp or 0.06, cfg.gust_amp or 0.8
    self.hair_move = {              wind_t     = 0,             gust_t        = 0,     gust_wait = _rand(0.9, 2.6),   gust_from = 0,
        gust_target = 0,            gust_value = 0,             gust_travel_t = 0.45,  phase     = "idle",            amp       = 0.26,
        detail_amp  = _detail_amp,  gust_amp   = _gust_amp,     offset        = 0,     value     = 0,                 velocity  = 0,                 
        stiffness   = 20,           damping    = 7.5,           shove      = 0,
    }
    return self.hair_move
end

--------------------------------------------
--- set hair wind offset 
--------------------------------------------
--- Helper: apply hair movement 
local function _apply_hair_movement(self)
    local model = self.model;                       if not model or not model.setParamValuePost then return end

    local hair_move = _init_hair_move(self)
    local cfg = self.hair_cfg or {}
    --- base wind = slow sway + fine flutter
    local base = hair_move.amp * sin((cfg.wind_speed or 0.8) * hair_move.wind_t)
               + hair_move.detail_amp * sin((cfg.detail_speed or 1.9) * hair_move.wind_t + 0.8)
    local wind = hair_move.value + base
    local hair_params = self.hair_params or {}

    for _, p in ipairs(hair_params) do
        --- each hair part can add its own phase-shifted detail motion
        local detail = (p.detail or 0.05) * sin((p.detail_speed or 2.3) * hair_move.wind_t + (p.phase or 0))
        local local_wind = _clamp(wind + detail, -1, 1)
        model:setParamValuePost(p.id, p.scale * local_wind)
    end
end

----____________________________________
--- main: set_hair_wind_offset
---_____________________________________
function Chara:set_hair_wind_offset(v)
    local hair_move  = _init_hair_move(self)
    hair_move.offset = _clamp(v, -1, 1)
    _apply_hair_movement(self)
end

---------------------------------
--- set hair movement 
---------------------------------
function Chara:set_hair_movement(v)
    local hair_move = _init_hair_move(self)
    local target    = _clamp(v, -1, 1)
    local delta     = target - hair_move.value

    hair_move.value, hair_move.velocity = hair_move.value + 0.2*delta, hair_move.velocity + 6.5*delta
    hair_move.shove    = target
    _apply_hair_movement(self)
end

-------------------------------------------
--- clear hair movement 
-------------------------------------------
function Chara:clear_hair_movement()
    local hair_move = _init_hair_move(self)
    hair_move.phase,  hair_move.shove      = "idle", 0
    hair_move.gust_t, hair_move.gust_wait  = 0, _rand(0.6, 1.8)
end

--------------------------------------
--- update hair movement
--------------------------------------
--- Helper: start hair gust 
local function _start_hair_gust(hair_move)
    hair_move.phase,     hair_move.gust_t       = "gust", 0
    --- gust_target is the temporary burst the hair will travel toward
    --- gust_from is the current gust value at the moment the burst starts
    hair_move.gust_from, hair_move.gust_target  = hair_move.gust_value, _rand(-hair_move.gust_amp, hair_move.gust_amp)
    hair_move.gust_travel_t  = _rand(0.45, 1.10) + 0.2
end

--- Helper: update hair idle 
local function _update_hair_idle(hair_move, dt)
    hair_move.gust_wait = hair_move.gust_wait - dt
    --- while waiting, the hair only follows the slow wind + spring state
    if hair_move.gust_wait > 0 then return end
    _start_hair_gust(hair_move)
end

--- Helper: update hair gust 
local function _update_hair_gust(hair_move, dt)
    hair_move.gust_t = hair_move.gust_t + dt
    local t = _clamp(hair_move.gust_t / max(hair_move.gust_travel_t, 0.001), 0, 1)
    
    --- interpolate from gust_from to gust_target over gust_travel_t
    hair_move.gust_value = _lerp(hair_move.gust_from, hair_move.gust_target, t)
    if t < 1 then return end

    --- once the burst lands, decay back toward a smaller settle motion
    hair_move.phase        = "settle"
    hair_move.gust_t,      hair_move.gust_from      = 0, hair_move.gust_value
    hair_move.gust_target, hair_move.gust_travel_t  = 0.25*hair_move.gust_target, _rand(0.7, 1.8)
end

--- Helper: update hair settle
local function _update_hair_settle(hair_move, dt)
    hair_move.gust_t = hair_move.gust_t + dt
    local t = _clamp(hair_move.gust_t / max(hair_move.gust_travel_t, 0.001), 0, 1)
    
    --- settle is the tail of the gust, fading back to calm
    hair_move.gust_value = _lerp(hair_move.gust_from, hair_move.gust_target, t)
    if t < 1 then return end
    
    hair_move.phase, hair_move.gust_t, hair_move.gust_wait  = "idle", 0, _rand(1.1, 2.4)
end

---___________________________________________________
--- main: update_hair_movement
---___________________________________________________
function Chara:update_hair_movement(dt)
    local hair_move   = _init_hair_move(self)
    hair_move.wind_t  = hair_move.wind_t + dt

    --- phase drives the random gust cycle: idle -> gust -> settle -> idle
    if     hair_move.phase == "idle"   then _update_hair_idle(hair_move, dt)
    elseif hair_move.phase == "gust"   then _update_hair_gust(hair_move, dt)
    elseif hair_move.phase == "settle" then _update_hair_settle(hair_move, dt) end

    --- spring-damper keeps movement smooth and prevents abrupt snaps
    --- offset = manual bias, gust_value = transient burst, shove = short push from input
    --- shove acts like a temporary assist from direct movement; it fades out over time
    local target = _clamp(hair_move.offset + hair_move.gust_value + 0.35*hair_move.shove, -1, 1)
    --- stiffness pulls toward target; damping subtracts velocity so the motion settles instead of oscillating
    local accel  = hair_move.stiffness*(target - hair_move.value) - hair_move.damping*hair_move.velocity

    hair_move.velocity  = hair_move.velocity + accel * dt
    hair_move.value     = _clamp(hair_move.value + hair_move.velocity * dt, -1, 1)
    hair_move.shove     = _lerp(hair_move.shove, 0, min(1, 5.5 * dt))

    _apply_hair_movement(self)
end

end
