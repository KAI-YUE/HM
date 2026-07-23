local SndUtils = require("HMfns.utils.sound_utils")
local Unlock   = require("HMfns.systems.unlocks")
local Timer    = require("HMfns.systems.timer")
-- local HUDMgr   = require("HMui.hud.hud_mgr")

local handle_unlock = Unlock.handle_unlock_request
local play_clip     = SndUtils.play_clip
local sleep, max    = Timer.sleep, math.max

local _ta  = "after"
local Y, N = true, false

local M = {}
-------------------------------------
--- Sort hand suit | Value
-------------------------------------
function M.sort_hand_suit(gm)  gm.hand:sort("suit desc"); play_clip(gm, "paper1") end
function M.sort_hand_value(gm) gm.hand:sort("desc"); play_clip(gm, "paper1") end


return M