local LM = love.math

local min, max = math.min, math.max
local sin      = math.sin
local Y, N     = true, false

return function (Chara)
local function _rand(a, b)        return a + (b - a) * LM.random() end
local function _clamp(v, lo, hi)  return max(lo, min(hi, v or 0)) end
local function _lerp(a, b, t)     return a + (b - a) * t end

--- Helper: init mouth move
local function _init_mouth_move(self)
    if self.mouth_move then return self.mouth_move end
    self.mouth_move = {
        --- basics
        open        = 0,       form        = 0,    target_open = 0,
        target_form = 0,       speech_t    = 0,

        --- phase & mode
        phase = "silent",      mode = "cycle",     active = N,

        --- timer settings
        timer = 0,             hold_t = 0.06,      open_t = 0.07, 
        close_t = 0.10,        talk_amp = 0.65,    form_amp = 0.18,
        smooth = 10.0,  
        
        --- audio settings
        audio_level = 0,       audio_delta = 0,    gate = 0.03,
    }

    return self.mouth_move
end

---------------------------------------------
--- start automatic talking cycle
---------------------------------------------
function Chara:start_mouth_movement()
    local mouth_move = _init_mouth_move(self)
    mouth_move.active, mouth_move.mode   = Y,      "cycle"
    mouth_move.phase,  mouth_move.timer  = "wait", _rand(0.02, 0.12)
end

-------------------------------------------------
--- set mouth level directly
-------------------------------------------------
--- Helper: apply mouth movement
local function _apply_mouth_movement(self)
    local model = self.model;                  if not model or not model.setParamValuePost then return end

    local mouth_move = _init_mouth_move(self)
    model:setParamValuePost("ParamMouthOpenY", _clamp(mouth_move.open, 0,  1))
    model:setParamValuePost("ParamMouthForm",  _clamp(mouth_move.form, -1, 1))
end

---_______________________________________________
--- main: set_mouth_level
---_______________________________________________
function Chara:set_mouth_level(v)
    local mouth_move = _init_mouth_move(self)

    mouth_move.active,       mouth_move.target_open  = Y,         _clamp(v, 0, 1)
    mouth_move.mode,         mouth_move.phase        = "direct",  "direct"
    mouth_move.audio_level,  mouth_move.audio_delta  = mouth_move.target_open, 0

    _settle_mouth(mouth_move, 1)
    _apply_mouth_movement(self)
end

---------------------------------------------
--- set mouth form
---------------------------------------------
function Chara:set_mouth_form(v)
    local mouth_move,       target_form      = _init_mouth_move(self), _clamp(v, -1, 1)
    mouth_move.target_form, mouth_move.form  = target_form,            (mouth_move.active and mouth_move.form or target_form)
    _apply_mouth_movement(self)
end

----------------------------------------------------------------------
--- set_mouth_audio: drive mouth from audio envelope values
----------------------------------------------------------------------
function Chara:set_mouth_audio(level, delta)
    local mouth_move  = _init_mouth_move(self)
    mouth_move.active = Y
    mouth_move.mode,        mouth_move.phase       = "audio", "audio"
    mouth_move.audio_level, mouth_move.audio_delta = _clamp(level, 0, 1), _clamp(delta or 0, 0, 1)
end

----------------------------------------------
--- clear mouth movement
----------------------------------------------
function Chara:clear_mouth_movement() self:stop_mouth_movement(Y) end

function Chara:stop_mouth_movement(reset_form)
    local mouth_move = _init_mouth_move(self)
    mouth_move.active,      mouth_move.mode        = N, "cycle"
    mouth_move.target_open, mouth_move.phase       = 0, "silent"
    mouth_move.audio_level, mouth_move.audio_delta = 0, 0
    if reset_form == Y then mouth_move.target_form, mouth_move.form = 0, 0 end
    _apply_mouth_movement(self)
end

---------------------------------------------
--- update mouth movement
---------------------------------------------
--- Helper: settle mouth to current targets
local function _settle_mouth(mouth_move, dt)
    local t = min(1, mouth_move.smooth * dt)
    mouth_move.open, mouth_move.form = _lerp(mouth_move.open, mouth_move.target_open, t), _lerp(mouth_move.form, mouth_move.target_form, min(1, 0.8 * mouth_move.smooth * dt))
end

--- Helper: close and settle mouth
local function _close_and_settle_mouth(self, mouth_move, dt)
    mouth_move.target_open = 0
    _settle_mouth(mouth_move, dt)
    return _apply_mouth_movement(self)
end

--- Helper: update mouth from audio-like level
local function _update_mouth_audio(mouth_move, dt)
    mouth_move.speech_t = mouth_move.speech_t + dt

    local level = mouth_move.audio_level
    if level <= mouth_move.gate then mouth_move.target_open, mouth_move.target_form = 0, _lerp(mouth_move.target_form, 0, min(1, 6*dt))
    else
        local wobble = 0.08*sin((7 + 18 * mouth_move.audio_delta) * mouth_move.speech_t)
        mouth_move.target_open, mouth_move.target_form = _clamp(level + wobble, 0, 1), _clamp((2*LM.random() - 1)*mouth_move.form_amp*(0.35 + mouth_move.audio_delta), -1, 1)
    end

    _settle_mouth(mouth_move, dt)
end

--- Helper: start mouth flap
local function _start_mouth_flap(mouth_move)
    mouth_move.phase,       mouth_move.timer        = "open", 0
    mouth_move.open_t,      mouth_move.hold_t       = _rand(0.04, 0.08), _rand(0.02, 0.06)
    mouth_move.close_t                              = _rand(0.05, 0.12)
    mouth_move.target_open, mouth_move.target_form  = _rand(0.35, mouth_move.talk_amp), _rand(-mouth_move.form_amp, mouth_move.form_amp)
end

--- Helper: update mouth wait
local function _update_mouth_wait(mouth_move, dt)
    mouth_move.timer        = mouth_move.timer - dt
    mouth_move.target_open, mouth_move.target_form  = 0, _lerp(mouth_move.target_form, 0, min(1, 5*dt))

    _settle_mouth(mouth_move, dt)
    if mouth_move.timer > 0 then return end
    _start_mouth_flap(mouth_move)
end

--- Helper: update mouth open
local function _update_mouth_open(mouth_move, dt)
    mouth_move.timer = mouth_move.timer + dt
    local t = _clamp(mouth_move.timer / max(mouth_move.open_t, 0.001), 0, 1)
    
    mouth_move.open, mouth_move.form = _lerp(mouth_move.open, mouth_move.target_open, t), _lerp(mouth_move.form, mouth_move.target_form, t)
    if t < 1 then return end
    
    mouth_move.phase, mouth_move.timer = "hold", 0
end

--- Helper: update mouth hold
local function _update_mouth_hold(mouth_move, dt)
    mouth_move.timer, mouth_move.open, mouth_move.form = mouth_move.timer + dt, mouth_move.target_open, mouth_move.target_form
    if mouth_move.timer < mouth_move.hold_t then return end
    mouth_move.phase, mouth_move.timer = "close", 0
end

--- Helper: update mouth close
local function _update_mouth_close(mouth_move, dt)
    mouth_move.timer = mouth_move.timer + dt
    local t = _clamp(mouth_move.timer / max(mouth_move.close_t, 0.001), 0, 1)

    mouth_move.open, mouth_move.form = _lerp(mouth_move.target_open, 0, t), _lerp(mouth_move.target_form, 0, t)
    if t < 1 then return end
    mouth_move.phase, mouth_move.timer, mouth_move.target_open = "wait", _rand(0.06, 0.24), 0
end

---________________________________________________
--- main: update_mouth_movement
---________________________________________________
function Chara:update_mouth_movement(dt)
    local mouth_move = _init_mouth_move(self)

    if     not mouth_move.active       then return _close_and_settle_mouth(self, mouth_move, dt) end
    if     mouth_move.mode == "audio"  then _update_mouth_audio(mouth_move, dt); return _apply_mouth_movement(self); end
    if     mouth_move.mode == "direct" then _settle_mouth(mouth_move, dt);       return _apply_mouth_movement(self); end
    if     mouth_move.phase == "wait"  then _update_mouth_wait(mouth_move, dt)
    elseif mouth_move.phase == "open"  then _update_mouth_open(mouth_move, dt)
    elseif mouth_move.phase == "hold"  then _update_mouth_hold(mouth_move, dt)
    elseif mouth_move.phase == "close" then _update_mouth_close(mouth_move, dt)
    else   mouth_move.phase = "wait"; mouth_move.timer = _rand(0.02, 0.12); _update_mouth_wait(mouth_move, dt); end

    _apply_mouth_movement(self)
end

end
