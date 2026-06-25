local LM = love.math

local min, max = math.min, math.max
local sin  = math.sin
local Y, N = true, false

return function (Chara)
---------------------------------------------
--- update blink
---------------------------------------------
--- Helper: _rand | _clamp | _lerp
local function _rand(a, b) return a + (b - a) * LM.random() end
local function _clamp(v, lo, hi) return max(lo, min(hi, v or 0)) end
local function _lerp(a, b, t) return a + (b - a) * t end

--- Helper: init blink driver
local function _init_blink_driver(self)
    if self.blink_state then return self.blink_state end

    self.blink_state = {
        phase = "idle",   timer = _rand(1.2, 3.0),              value = 1,     close_t = 0.07,
        hold_t = 0.03,   open_t = 0.10,             double_blink_odds = 0.08, thoughtful_close_odds = 0.04,
        close_hold_t = 0.5 }

    return self.blink_state
end

--- Helper: blink update
local function _queue_next_blink(st, quick)
    st.value = 1
    st.phase = "idle"
    st.timer = quick and _rand(0.05, 0.16) or _rand(1.2, 4.0)
end

--- Helper: start blink
local function _start_blink(st)
    st.phase,    st.timer        = "close", 0
    st.close_t,  st.hold_t       = _rand(0.04, 0.08), _rand(0.02, 0.05)
    st.open_t,   st.close_hold_t = _rand(0.05, 0.11), LM.random() < st.thoughtful_close_odds and _rand(0.18, 0.55) or st.hold_t
end

--- Helper: apply eye params
local function _apply_eye_params(self, v)
    local model = self.model
    if not model or not model.setParamValuePost then return end

    model:setParamValuePost("ParamEyeLOpen", v)
    model:setParamValuePost("ParamEyeROpen", v)
end

--- Helper: eyes_closed
function Chara:eyes_closed() return self.states.eye_close and self.states.eye_close.is end

--- Helper: close eyes
function Chara:close_eyes()
    local st = _init_blink_driver(self)
    if self.states.eye_close then self.states.eye_close.is = true end
    st.phase, st.timer, st.value = "idle", 0, 0
    _apply_eye_params(self, 0)

    self:set_eyebrow_y(-0.9)
end

--- Helper: open eyes
function Chara:open_eyes(min_wait, max_wait)
    local st = _init_blink_driver(self)
    if self.states.eye_close then self.states.eye_close.is = false end
    st.phase = "idle"
    st.timer = _rand(min_wait or 0.1, max_wait or 0.5)
    st.value = 1
    _apply_eye_params(self, 1)
end

--- Helper: queue thoughtful close
function Chara:queue_thoughtful_close(min_t, max_t)
    if self:eyes_closed() then return end
    local st = _init_blink_driver(self)
    st.phase = "close"
    st.timer, st.value    = 0, 1
    st.close_t, st.open_t = _rand(0.04, 0.08), _rand(0.06, 0.14)
    st.close_hold_t       = _rand(min_t or 0.25, max_t or 0.6)
end

--- Helper: update_blink_idle
local function _update_blink_idle(st, dt)
    st.timer = st.timer - dt
    if st.timer <= 0 then _start_blink(st) end
end

--- Helper: update_blink_close
local function _update_blink_close(st, dt)
    st.timer = st.timer + dt
    st.value = max(0, 1 - st.timer / max(st.close_t, 0.001))
    if st.timer < st.close_t then return end
    st.phase, st.timer, st.value = "hold", 0, 0
end

--- Helper: update_blink_hold for closed eyes
local function _update_blink_hold(st, dt)
    st.timer = st.timer + dt
    st.value = 0
    if st.timer < st.close_hold_t then return end
    st.phase, st.timer = "open", 0
end

--- Helper: update blink open
local function _update_blink_open(st, dt)
    st.timer = st.timer + dt
    st.value = min(1, st.timer / max(st.open_t, 0.001))
    if st.timer < st.open_t then return end
    local quick = (st.close_hold_t <= 0.08) and (LM.random() < st.double_blink_odds)
    _queue_next_blink(st, quick)
end

---_________________________________________
--- main: update blink
---_________________________________________
function Chara:update_blink(dt)
    if self:eyes_closed() then _apply_eye_params(self, 0); return end

    local st = _init_blink_driver(self)

    if     st.phase == "idle"  then _update_blink_idle(st, dt)
    elseif st.phase == "close" then _update_blink_close(st, dt)
    elseif st.phase == "hold"  then _update_blink_hold(st, dt)
    elseif st.phase == "open"  then _update_blink_open(st, dt)
    end

    _apply_eye_params(self, st.value)
end

----------------------------------
--- Update eye (balls) movement
----------------------------------
--- Helper: init eye movement
local function _init_eye_move(self)
    if self.eye_move then return self.eye_move end

    self.eye_move = {                  x = 0,             y = 0,                 start_x = 0,         start_y = 0,      target_x = 0,       target_y = 0,
        offset_x = 0.3,         offset_y = 0,
        breath_t = 0,              phase = "idle",    timer = _rand(0.4, 3.2),  travel_t = 0.18,    elapsed_t = 0,    idle_amp_x = 0.05,  idle_amp_y = 0.03,
        look_amp_x = 0.35,    look_amp_y = 0.22,     manual = N,
    }
    return self.eye_move
end

--- Helper: apply eye movement
local function _apply_eye_movement(self)
    local model = self.model
    if not model or not model.setParamValuePost then return end

    local eye_move = _init_eye_move(self)
    model:setParamValuePost("ParamEyeBallX", eye_move.x + eye_move.offset_x)
    model:setParamValuePost("ParamEyeBallY", eye_move.y + eye_move.offset_y)
end

--- Helper: pick idle target
local function _pick_idle_target(eye_move)
    eye_move.start_x, eye_move.start_y = eye_move.x, eye_move.y
    eye_move.target_x  = _rand(-eye_move.look_amp_x, eye_move.look_amp_x)
    eye_move.target_y  = _rand(-eye_move.look_amp_y, eye_move.look_amp_y)
    eye_move.travel_t  = _rand(0.18, 0.45)
    eye_move.elapsed_t = 0
    eye_move.phase     = "travel"
end

--- Helper: update eye idle wait
local function _update_eye_idle_wait(eye_move, dt)
    eye_move.timer = eye_move.timer - dt
    if eye_move.timer > 0 then return end
    _pick_idle_target(eye_move)
end

--- Helper: update eye idle travel
local function _update_eye_idle_travel(eye_move, dt)
    eye_move.elapsed_t = eye_move.elapsed_t + dt
    local t = min(1, eye_move.elapsed_t / max(eye_move.travel_t, 0.001))
    eye_move.x = _lerp(eye_move.start_x, eye_move.target_x, t)
    eye_move.y = _lerp(eye_move.start_y, eye_move.target_y, t)
    if t < 1 then return end
    eye_move.phase = "settle"
    eye_move.timer = _rand(0.35, 1.1)
end

--- Helper: update eye idle settle
local function _update_eye_idle_settle(eye_move, dt)
    eye_move.timer = eye_move.timer - dt
    eye_move.x = _lerp(eye_move.x, eye_move.target_x, math.min(1, 3*dt))
    eye_move.y = _lerp(eye_move.y, eye_move.target_y, math.min(1, 3*dt))
    if eye_move.timer > 0 then return end
    eye_move.phase = "idle"
    eye_move.timer = _rand(0.9, 3.6) + 0.5
end

--- Helper: clear eye movement
function Chara:clear_eye_movement()
    local eye_move  = _init_eye_move(self)
    eye_move.manual = N
    eye_move.phase  = "idle"
    eye_move.timer  = _rand(0.2, 0.8)
    eye_move.start_x, eye_move.start_y   = eye_move.x, eye_move.y
    eye_move.target_x, eye_move.target_y = eye_move.x, eye_move.y
end

---____________________________________
--- update eye movement
--_____________________________________
function Chara:update_eye_movement(dt)
    local eye_move = _init_eye_move(self)

    if  eye_move.manual then return _apply_eye_movement(self) end
    eye_move.breath_t = eye_move.breath_t + dt
    if     eye_move.phase == "idle"   then _update_eye_idle_wait(eye_move, dt)
    elseif eye_move.phase == "travel" then _update_eye_idle_travel(eye_move, dt)
    elseif eye_move.phase == "settle" then _update_eye_idle_settle(eye_move, dt)
    end

    local breath_x = eye_move.idle_amp_x * sin(0.8 * eye_move.breath_t)
    local breath_y = eye_move.idle_amp_y * sin(1.3 * eye_move.breath_t + 0.7)
    eye_move.x = _clamp(eye_move.x + breath_x * dt, -1, 1)
    eye_move.y = _clamp(eye_move.y + breath_y * dt, -1, 1)

    _apply_eye_movement(self)
end

--------------------------------------
--- set eye movement
--------------------------------------
function Chara:set_eye_movement(x, y)
    local eye_move = _init_eye_move(self)
    eye_move.manual = Y
    eye_move.x = _clamp(x, -1, 1)
    eye_move.y = _clamp(y, -1, 1)
    eye_move.start_x,  eye_move.start_y  = eye_move.x, eye_move.y
    eye_move.target_x, eye_move.target_y = eye_move.x, eye_move.y
    _apply_eye_movement(self)
end

----------------------------------
--- Update eyebrow movement
----------------------------------
--- Helper: init eyebrow movement
local function _init_eyebrow_move(self)
    if self.eyebrow_move then return self.eyebrow_move end

    self.eyebrow_move = {   x = 0,          y = 0,     target_x = 0, target_y = 0, offset_x = 0, offset_y = 0,
        link_x = 1.5,     link_y = 2,  smooth = 5.5,     manual = N,      form = 0 }
    return self.eyebrow_move
end

--- Helper: apply eyebrow movement
local function _apply_eyebrow_movement(self)
    local model = self.model
    if not model or not model.setParamValuePost then return end

    local eyebrow_move = _init_eyebrow_move(self)
    local bx = _clamp(eyebrow_move.x + eyebrow_move.offset_x, -1, 1)
    local by = _clamp(eyebrow_move.y + eyebrow_move.offset_y, -1, 1)
    local bf = _clamp(eyebrow_move.form, -1, 1)

    model:setParamValuePost("ParamBrowLX", bx)
    model:setParamValuePost("ParamBrowRX", bx)
    model:setParamValuePost("ParamBrowLY", by)
    model:setParamValuePost("ParamBrowRY", by)
    model:setParamValuePost("ParamBrowLForm", bf)
    model:setParamValuePost("ParamBrowRForm", bf)
end

--________________________________________
-- Main: update eyebrow movement 
--________________________________________
function Chara:update_eyebrow_movement(dt)
    local eyebrow_move = _init_eyebrow_move(self)

    if eyebrow_move.manual then return _apply_eyebrow_movement(self) end
    
    local eye_move = _init_eye_move(self)
    eyebrow_move.target_x = eyebrow_move.link_x * eye_move.x
    eyebrow_move.target_y = eyebrow_move.link_y * eye_move.y
    local t = math.min(1, eyebrow_move.smooth * dt)
    eyebrow_move.x = _lerp(eyebrow_move.x, eyebrow_move.target_x, t)
    eyebrow_move.y = _lerp(eyebrow_move.y, eyebrow_move.target_y, t)

    _apply_eyebrow_movement(self)
end

-----------------------------------------------
--- set eyebrow movement 
-----------------------------------------------
function Chara:set_eyebrow_movement(x, y)
    local eyebrow_move = _init_eyebrow_move(self)
    eyebrow_move.manual = Y
    eyebrow_move.x = _clamp(x, -1, 1)
    eyebrow_move.y = _clamp(y, -1, 1)
    eyebrow_move.target_x = eyebrow_move.x
    eyebrow_move.target_y = eyebrow_move.y
    _apply_eyebrow_movement(self)
end

--- move eyebrow y only
function Chara:set_eyebrow_y(y)
    local eyebrow_move = _init_eyebrow_move(self)
    eyebrow_move.manual = Y
    eyebrow_move.y = _clamp(y, -1, 1)
    eyebrow_move.target_y = eyebrow_move.y
    _apply_eyebrow_movement(self)
end

-------------------------------------------
--- Clear eyebrow movement
-------------------------------------------
function Chara:clear_eyebrow_movement()
    local eyebrow_move = _init_eyebrow_move(self)
    eyebrow_move.manual   = N
    eyebrow_move.target_x = eyebrow_move.x
    eyebrow_move.target_y = eyebrow_move.y
end

------------------------------------------------------------------------------------------
--- Eyebrow form: Dedicated eyebrow-form setter so thinking-time form can be driven separately.
------------------------------------------------------------------------------------------
function Chara:set_eyebrow_form(v)
    local eyebrow_move = _init_eyebrow_move(self)
    eyebrow_move.form = _clamp(v, -1, 1)
    _apply_eyebrow_movement(self)
end

---------------------------------------------
--- clear eyebrow form 
---------------------------------------------
function Chara:clear_eyebrow_form() self:set_eyebrow_form(0) end

end
