local GMgr  = require("HMGmgr")
local M = {}

function M.load()
    G = GMgr();
    math.randomseed(G.seed)
    require ("HMfns/state_events")
    require ("HMfns/common_events")
    require ("HMfns._misc_functions")
    require ("bit")
	G:start_up()
	
	local os = love.system.getOS()
	if os == "OS X" or os == "Windows" then 
		local st = "luasteam"
		--To control when steam communication happens, make sure to send updates to steam as little as possible
		if os == "OS X" then
			local dir = love.filesystem.getSourceBaseDirectory()
			local old_cpath = package.cpath
			package.cpath = package.cpath .. ";" .. dir .. "/?.so"
			package.cpath = old_cpath
        end

		st.send_control = {
			last_sent_time = -200,
			last_sent_stage = -1,
			force = false,
		}
		if not (st.init and st:init()) then love.event.quit() end
		G.STEAM = st
	end
	love.mouse.setVisible(false)
end

return M