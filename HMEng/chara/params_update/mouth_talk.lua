local SND = require("HMfns.utils.sound_utils")

local play_clip  = SND.play_clip
local LSND, LF   = love.sound, love.filesystem

local min, max, abs, floor = math.min, math.max, math.abs, math.floor

local Y, N = true, false

return function (Chara)
-------------------------------------------------
--- Emit talking
-------------------------------------------------
--- Helper: init sync 
local function _init_sync(sync)
    sync.current_key, sync.elapsed  = "", 0
    sync.prev_level,  sync.level    = 0,  0
    sync.delta,       sync.frame    = 0, -1
end

--- Helper: dialogue_voice_on | talk_tag | get_audio_sync | reset talking state
local function dialogue_voice_on(gm)    local snd = gm.SET.s_snd; return not (snd and snd.dialogue_voice == N) end
local function _talk_tag(obj)           return "talking:" .. tostring(obj.ID) end
local function _get_audio_sync(gm)      return gm.audio_sync end
local function _reset_talking_state(gm) local sync = _get_audio_sync(gm); if sync then _init_sync(sync) end end

---__________________________
--- main: emit_talking
---__________________________
function Chara:emit_talking(snd_code, rate, vol)
    local gm, rate  = self.gm,         rate or 1
    local tag, vol  = _talk_tag(self), vol or 0.8
    self._audio = { enabled = Y, snd_code = snd_code, playback_rate = rate, loop = N, start_t = 0, tag = tag }

    _reset_talking_state(gm)
    if dialogue_voice_on(gm) then play_clip(gm, snd_code, rate, vol, { tag = tag, voice = Y }) end
end

-------------------------------------------------
--- Interrupt talking
-------------------------------------------------
function Chara:interrupt_talking()
    local gm = self.gm;                 if self._audio then self._audio.enabled = N end
    local sync = _get_audio_sync(gm);   if sync then _init_sync(sync) end

    self:clear_mouth_movement()
    gm.SndMgr.channel:push({ type = "stop_tag", tag = _talk_tag(self) })
end

-----------------------------------------------------
--- Update: update mouth audio input
-----------------------------------------------------
--- Helper: get sound sample 
local function _get_sound_sample(sound_data, i, channel)
    local ok, v = pcall(sound_data.getSample, sound_data, i, channel);  if ok then return v or 0 end
    ok, v = pcall(sound_data.getSample, sound_data, i);                 return ok and (v or 0) or 0
end

--- Helper: load audio envelope
local function _load_audio_envelope(gm, cfg)
    local path = (cfg.snd_code and "resources/sounds/" .. cfg.snd_code .. ".ogg");   if not path then return end

    local sync    = _get_audio_sync(gm);                                             if not LF.getInfo(path) then sync.tracks[path] = N; return end
    local cached  = sync.tracks[path];                                               if cached ~= nil        then return cached end; 
    local ok, sound_data = pcall(LSND.newSoundData, path);                           if not ok or not sound_data then sync.tracks[path] = N; return end

    local rate, count              = sound_data:getSampleRate(),        sound_data:getSampleCount()  -- LOVE snd analysis 
    local channels, bucket_frames  = sound_data:getChannelCount() or 1, max(1, floor(rate * sync.step_t))
    local env, acc, n, peak        = {}, 0, 0, 0

    for i = 0, count - 1 do
        local frame = 0
        for c = 1, channels do frame = frame + abs(_get_sound_sample(sound_data, i, c)) end
        frame = frame / max(channels, 1)
        acc, n = acc + frame, n + 1

        if n >= bucket_frames then local level = acc / n; env[#env + 1], peak = level, max(peak, level); acc, n = 0, 0 end
    end

    if    n > 0 then local level = acc / n; env[#env + 1], peak = level, max(peak, level) end
    if peak > 0 then for i = 1, #env do env[i] = min(1, (env[i] / peak)^0.7) end end

    local track = { env = env, step_t = sync.step_t, duration = count/max(rate, 1), path = path }
    sync.tracks[path] = track
    return track
end

--- Helper: sample audio input
local function _sample_audio_input(self, dt)
    local gm, cfg  = self.gm, self._audio;                 if not (gm and cfg and cfg.enabled) then return end
    local sync, FRS = _get_audio_sync(gm), self.FRS;       if not sync then return end
    
    if not dialogue_voice_on(gm) then sync.level, sync.delta = 0, 0; return sync end
    if sync.frame == FRS.f_m then return sync end
    sync.frame     = FRS.f_m

    local track = _load_audio_envelope(gm, cfg);            if not track or not track.env[1] then sync.level, sync.delta = 0, 0; return sync end

    local key = track.path
    if sync.current_key ~= key then sync.current_key, sync.elapsed, sync.prev_level = key, cfg.start_t or 0, 0
    else                            sync.elapsed = sync.elapsed + dt * (cfg.playback_rate or 1) end

    local duration = max(track.duration, track.step_t)
    if cfg.loop == N then sync.elapsed = min(sync.elapsed, duration)
    else                  sync.elapsed = sync.elapsed % duration end

    local idx    = min(#track.env, 1 + floor(sync.elapsed / track.step_t))
    local level  = track.env[idx] or 0
    local delta  = min(1, 4 * abs(level - sync.prev_level))

    sync.prev_level, sync.level, sync.delta = level, level, delta
    return sync
end

---___________________________
--- Update mouth_audio_sync
---___________________________
function Chara:update_mouth_audio_input(dt)
    local sync = _sample_audio_input(self, dt);     if not sync then return end
    self:set_mouth_audio(sync.level, sync.delta)
end

end
