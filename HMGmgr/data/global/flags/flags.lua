local TabUtils  = require("HMfns.utils.table_utils")
local LS        = love.system

local contains  = TabUtils.contains

local TPC = { "Windows", "OS X" }
local TPS = { "ps4", "ps5" }

local Y, N = true, false

return function (GMgr)
-----------------------------
--- flags
----------------------------------
--- Helper: is_shadow_off
function GMgr:is_shadow_off() return self.SET.s_graphics.shadows ~= "On" end

--- Helper: init_flags
function GMgr:init_flags()
    self.F = { quit_btn = Y,   skip_tut = Y,   ext_url = Y, vid_set = Y,     verbose = Y,   rumble  = nil, swap_AB_pip = N, swap_AB_btns = N, swap_XY_btns = N, no_achm = N,
          disp_usrname = nil, eng_force = nil, hide_bg = N,     PS4 = N,  save_timer = 30, social_m = Y }

    local selfF, _os = self.F, LS.getOS()
    if contains(TPC, _os)        then selfF.social_m, selfF.save_timer, selfF.eng_force = Y, 5, N  end
    if _os == "Nintendo Switch"  then selfF.quit_btn, selfF.vid_set, selfF.rumble = N, N, 0.7;     selfF.verbose, selfF.no_achm, selfF.ext_url, selfF.hide_bg = N, Y, N, Y end
    if contains(TPS, _os)        then selfF.quit_btn, selfF.vid_set, selfF.rumble = N, N, 0.5;     selfF.verbose, selfF.PS4,     selfF.ext_url, selfF.hide_bg = N, N, N, Y end
    if _os == "xbox"             then selfF.disp_usrname, selfF.skip_tut, selfF.vid_set = Y, N, N; selfF.rumble, selfF.verbose,  selfF.ext_url, selfF.hide_bg = 1.0, N, N, Y end
end

end
