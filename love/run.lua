local min = math.min
local LT, LE, LH, LG = love.timer, love.event, love.handlers, love.graphics
local Y, N   = true, false

local M = {}
---------------------------------------------
--- run
---------------------------------------------
--- Helper: fps_cap
local function _fps_cap()
    local _fps_cap = (G.SET.fps_cap) or G.FPS_CAP or 500
    if _fps_cap == "auto" then return 144 else return _fps_cap end 
end

---_____________________________________________
--- main: run 
---_____________________________________________
function M.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if LT then LT.step() end

	local dt, dt_smooth, run_time = 0, 1/100, 0
    return function ()
        run_time = LT.getTime()
        if LE and G and G.CTRL then      -- Process events
            LE.pump()
            local _n, _a, _b, _c, _d, _e, _f, touched
            for name, a, b, c, d, e, f in LE.poll() do
                if     name == "quit"         then if not love.quit or not love.quit() then return a or 0 end 
                elseif name == "touchpressed" then touched = Y
                elseif name == "mousepressed" then _n, _a, _b, _c, _d, _e, _f = name, a, b, c, d, e, f
                else LH[name](a, b, c, d, e, f) end
            end
            if _n then LH["mousepressed"](_a, _b, _c, touched) end
        end

        if LT then dt = LT.step() end
        dt_smooth = min(0.85*dt_smooth + 0.15*dt, 0.05)
        love.update(dt_smooth) -- will pass 0 if love.timer is disabled

        if love.graphics and LG.isActive() then if love.draw then love.draw() end;  LG.present(); end
        run_time = min(LT.getTime() - run_time, 0.1)

        local _fps_cap = _fps_cap()
        G.FPS_CAP = _fps_cap
        if run_time < 1./_fps_cap then LT.sleep(1./_fps_cap - run_time) end
    end
end

--------------------------------
--- Quit
--------------------------------
function M.quit()
	if G.SndMgr then G.SndMgr.channel:push({ type = "stop" }) end
	if G.STEAM then G.STEAM:shutdown() end
end

return M
