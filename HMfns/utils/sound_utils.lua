local LA   = love.audio
local push = table.insert

local Y, N = true, false

local sound_utils = {}

---------------------------------------------
--- Queue or play a sound event
---------------------------------------------
function sound_utils.play_clip(gm, sound_code, per, vol, opts)
	if gm.F_MUTE or not sound_code then return end

    local SET, args = gm.SET, gm.args;       local _vol = SET.s_snd.volume or 0
    if _vol <= 1e-3 then return end;         args.play_sound = args.play_sound or {}
    opts = opts or {}
    
    local a = gm.args.play_sound
    a.type,   a.splash_vol,     a.crt,       a.sound_code    = "sound", gm.SPLASH_VOL, SET.s_graphics.crt, sound_code
    a.per,    a.music_control,  a.pitch_mod, a.state         = per, SET.music_control, gm.s_pitch, gm.g_state
    a.vol,    a.sound_settings, a.time,      a.overlay_menu  = vol, SET.s_snd, gm._T.real_s, not (not gm.UI.overlay_menu)
    a.tag, a.voice = opts.tag, opts.voice

    gm.SndMgr.channel:push(a);               return Y
end


---------------------------------------
--- modulate
---------------------------------------
function sound_utils.modulate(args, sources)
    if args.desired_track ~= "" then  -- ensure music is running when we want music
        for code, pool in pairs(sources) do if code:find("music") then local s = pool[1]; if not (s and s.sound and s.sound:isPlaying()) then sound_utils.restart_clip(args, sources) end; break end end
    end

    -- cleanup + update active sources
    for _, pool in pairs(sources) do
        local i = 1
        while i <= #pool do
            local snd = pool[i].sound
            if snd and snd:isPlaying() then
                local s = pool[i]
                if s.original_volume then sound_utils.set_sfx(s, args, sources) end
                i = i + 1
            else if snd then snd:release() end; table.remove(pool, i) end
        end
    end
end

--------------------------------------------------
--- play me
-------------------------------------------------
function sound_utils.play_me(args, sources)
    local code, per, vol = args.sound_code, args.per or 1, args.vol or 1
    local pool = sources[code] or {};               sources[code] = pool

    for _, s in ipairs(pool) do  -- reuse an idle source if possible
        if s.sound and not s.sound:isPlaying() then
            s.original_pitch, s.original_volume    = per, vol
            s.created_on_pause, s.created_on_state = args.overlay_menu, args.state
            s.sfx_handled, s.transition_timer      = 0, 0
            s.tag, s.voice = args.tag, args.voice or (code and code:find("_voice"))
            sound_utils.set_sfx(s, args, sources)
            LA.play(s.sound);                      return s
        end
    end
    
    local stream = code:find("music") or code:find("ambient")   -- otherwise create a new one
    local s = { sound = LA.newSource("resources/sounds/"..code..".ogg", stream and "stream" or "static"),
        sound_code = code,               original_pitch = per,
        original_volume = vol,           created_on_pause = not not args.overlay_menu,
        created_on_state = args.state,   sfx_handled = 0,
        transition_timer = 0,            tag = args.tag,
        voice = args.voice or (code and code:find("_voice")) }

    push(pool, s);                          sound_utils.set_sfx(s, args, sources)
    LA.play(s.sound);                       return s
end

---------------------------------------------------------
--- Restart clip
---------------------------------------------------------
function sound_utils.restart_clip(args, sources)
    for k, v in pairs(sources) do
        if not string.find(k,"music") then goto continue end 
        local prev_pitch, prev_volume = args.per or 1, args.vol or 1
        local prev_source = v[1]
        if prev_source then
            prev_pitch  = prev_source.original_pitch or prev_pitch
            prev_volume = prev_source.original_volume or prev_volume
        end
        for i, s in ipairs(v) do s.sound:stop() end

        sources[k], args.sound_code = {}, k
        args.per, args.vol          = prev_pitch, prev_volume
        local s = sound_utils.play_me(args, sources)
        s.initialized = Y
        ::continue::
    end
end

---------------------------------------------------------
--- Reset Sound States 
---------------------------------------------------------
function sound_utils.reset_snd_states(state, sources)
    local sources = sources or SOURCES
    for k, v in pairs(sources) do for i, s in ipairs(v) do s.created_on_state = state end end
end

---------------------------------------------------
--- ambient 
---------------------------------------------------
function sound_utils.ambient(args, sources)
    -- for k, v in pairs(sources) do
    -- local ac = args.ambient_control[k]
    -- if not ac then goto continue end 
    
    -- local vol = ac.vol;                 local ss  = args.sound_settings
    -- local start = (vol * (ss.volume/100) * (ss.SE_volume/100)) > 0

    -- for _, s in ipairs(v) do
    --     if s.sound and s.sound:isPlaying() and s.original_volume then
    --         s.original_volume = vol;    sound_utils.set_sfx(s, args)
    --         start = N;                  break
    --     end
    -- end
    -- if not start then goto continue end

    -- args.sound_code, args.vol, args.per = k, vol, ac.per
    -- sound_utils.play_me(args, sources)
    -- ::continue::
    -- end
end

---------------------------------------------------
--- set_sfx
---------------------------------------------------
function sound_utils.set_sfx(s, args, sources)
    if string.find(s.sound_code, "music") then 
        if s.sound_code == args.desired_track then s.current_volume = s.current_volume or 1; s.current_volume = (args.dt*3) + (1-(args.dt*3))*s.current_volume
        else s.current_volume = s.current_volume or 0; s.current_volume = (1-(args.dt*3))*s.current_volume end
        s.sound:setVolume(s.current_volume*s.original_volume*(args.sound_settings.volume/100.0)*(args.sound_settings.music_volume/100.0))
        -- s.sound:setVolume(0)
        s.sound:setPitch(s.original_pitch*args.pitch_mod)
        return 
    end
    
    if s.temp_pitch ~= s.original_pitch then 
        s.sound:setPitch(s.original_pitch)
        s.temp_pitch = s.original_pitch
    end
    local sound_vol = s.original_volume*(args.sound_settings.volume/100.0)*(args.sound_settings.SE_volume/100.0)
    if s.voice then
        sound_vol = (args.sound_settings.dialogue_voice == false) and 0 or sound_vol*((args.sound_settings.voice_volume or 100)/100.0)
    end
    if s.created_on_state == 13 then sound_vol = sound_vol*args.splash_vol end
    if sound_vol <= 0 then s.sound:stop()
    else s.sound:setVolume(sound_vol) end
end

-------------------------------------------------
--- stop audio 
-------------------------------------------------
function sound_utils.stop_audio(sources)  for _, source in pairs(sources) do for _, s in pairs(source) do if s.sound:isPlaying() then s.sound:stop() end end end end

-------------------------------------------------
--- stop tagged audio
-------------------------------------------------
function sound_utils.stop_tag(tag, sources)
    if not tag then return end
    for _, source in pairs(sources) do for _, s in pairs(source) do if s.tag == tag and s.sound and s.sound:isPlaying() then s.sound:stop() return end end end
end

-------------------------------------------
--- game start modulate snd 
-------------------------------------------
function sound_utils.start_modulate_sound(gm, dt)
    local st, gs, stg = gm.g_state, gm.g_states, gm.g_stage
    local A, SET, SND = gm.args, gm.SET, gm.SndMgr

    local a  = 2*dt  -- splash volume (smoothed)
    local on = (st == gs.splash) and 1 or 0
    gm.SPLASH_VOL = a*on + (gm.SPLASH_VOL or 1)*(1 - a)

    -- pick music track
    local desired_track =
        gm.video_soundtrack or
        ((st == gs.splash) and "") or
        (gm.booster_pack_sparkles and not gm.booster_pack_sparkles.REMOVED and "music2") or
        (gm.booster_pack_meteors  and not gm.booster_pack_meteors.REMOVED  and "music3") or
        (gm.booster_pack          and not gm.booster_pack.REMOVED          and "music2") or
        (gm.shop                 and not gm.shop.REMOVED                   and "music4") or
        (gm.GAME.blind and gm.GAME.blind.boss                              and "music5") or
        "music1"

    -- pitch (smoothed)
    do
        local target = ((not gm.normal_music_speed and st == gs.game_over) and 0.5) or 1
        gm.s_pitch = (gm.s_pitch or 1)*(1 - dt) + dt*target
    end

    -- ambient intensity
    SET.ambient_control = SET.ambient_control or {}
    A.score_intensity   = A.score_intensity   or {}

    -- ambient volumes (smoothed)
    local AC  = SET.ambient_control
    local mv  = (SET.s_snd.music_volume + 100)/200
    local cf  = A.chip_flames
    local mf  = A.mult_flames
    local dfl = (cf and cf.change or 0) + (mf and mf.change or 0)

    local per = { ambientOrgan1 = 0.7, ambientFire1 = 1.1, ambientFire2 = 1.05 }

    -- push to sound thread
    A.push = A.push or {}
    local p = A.push
    p.type, p.pitch_mod, p.state   = "modulate", gm.s_pitch, st
    p.time, p.dt, p.desired_track  = gm._T.real_s, dt, desired_track
    p.sound_settings, p.splash_vol = SET.s_snd, gm.SPLASH_VOL
    p.overlay_menu = not not gm.UI.overlay_menu
    p.ambient_control = AC

    SND.channel:push(p)
end

return sound_utils
