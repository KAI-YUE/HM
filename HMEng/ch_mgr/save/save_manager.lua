-- Runs as a saving thread: listens for save requests on "save_request" _ch

require "love.system"
require "love.timer"
require "love.thread"

local TabUtils  = require("HMfns.utils.table_utils")
local SaveUtils = require("HMEng.ch_mgr.save.save_utils")
local LS, LT    = love.system, love.thread

local contains    = TabUtils.contains
local _os, _arch  = LS.getOS(), jit.arch

local TARM  = { "arm64", "arm" }

local Y, N  = true, false

if (_os == "OS X") and  contains(TARM, _arch) then jit.off() end  -- Disable JIT on Apple Silicon for stability
local _ch = LT.getChannel("save_request")                         -- Thread channel

while Y do                                  -- Main loop
    local request = _ch:demand()            -- blocks until message arrives
    if not request then goto continue end

    if     request.type == "save_progress" then SaveUtils.handle_save_progress(request, _ch)
    elseif request.type == "save_settings" then SaveUtils.handle_save_settings(request)
    elseif request.type == "save_metrics"  then SaveUtils.handle_save_metrics(request)
    elseif request.type == "save_notify"   then SaveUtils.handle_save_notify(request)
    elseif request.type == "save_run"      then SaveUtils.handle_save_run(request) end

    ::continue::
end
