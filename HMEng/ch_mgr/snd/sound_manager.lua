require "love.audio"
require "love.sound"
require "love.system"

local push = table.insert
local LS, LT, LA, LF  = love.system, love.thread, love.audio, love.filesystem
local sound_utils = require("HMfns.utils.sound_utils")

local Y, N = true, false

if (LS.getOS() == "OS X") and (jit.arch == "arm64" or jit.arch == "arm") then jit.off() end

sreq = LT.getChannel("sound_request")   -- vars needed for sound manager thread
lch  = LT.getChannel("load_channel")
lch:push("audio thread start")

local snd_src = {}                      -- create all sounds from resources and play one each to load into mem
local sound_files = LF.getDirectoryItems("resources/sounds")

-----------------------------------------------------------------------------------------
for _, filename in ipairs(sound_files) do
    local extension = string.sub(filename, -4)
    if extension ~= ".ogg" then goto continue end 
    lch:push("audio file - "..filename);                  local sound_code = string.sub(filename, 1, -5)
    local s = { sound = LA.newSource("resources/sounds/"..filename, string.find(sound_code,"music") and "stream" or "static"), filepath = "resources/sounds/"..filename }
    
    snd_src[sound_code] = {};                             push(snd_src[sound_code], s)
    s.sound_code = sound_code;                            s.sound:setVolume(0)
    love.audio.play(s.sound);                             s.sound:stop()
    ::continue::
end

lch:push("finished")

while Y do                                          -- Main Loop: Monitor the channel for any new requests
    local request = sreq:demand()                   -- Value from channel
    if not request then goto continue end;          local _t = request.type

    if     _t == "sound"         then sound_utils.play_me(request, snd_src)
    elseif _t == "stop"          then sound_utils.stop_audio(snd_src)
    elseif _t == "stop_tag"      then sound_utils.stop_tag(request.tag, snd_src)
    elseif _t == "modulate"      then sound_utils.modulate(request, snd_src); if request.ambient_control then sound_utils.ambient(request, snd_src) end
    elseif _t == "restart_music" then sound_utils.restart_clip(snd_src)
    elseif _t == "reset_states"  then for k, v in pairs(snd_src) do for i, s in ipairs(v) do s.created_on_state = request.state end end end
    ::continue::
end
