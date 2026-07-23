local LT, LG, LW = love.timer, love.graphics, love.window
local push = table.insert

local M = {}

------------------------------------------
--- Sleep 
------------------------------------------
function M.sleep(gm, time, queue)
    local EM, t = gm.E_MANAGER, time or 1
	EM:enqueue_event( {queue = queue, trigger = "after", delay = t })
    return true
end

-------------------------------------------------------------
--- Timer checkpoint 
--------------------------------------------------------------
function M.timer_cpt(gm, label, type, reset) gm.PREV_GARB = gm.PREV_GARB or 0 end

--------------------------------------------------------------------
--- tick gc (garbage collect)
--------------------------------------------------------------------
function M.tick_gc(time_budget, memory_ceiling, disable_otherwise)
	local time_budget, memory_ceiling = time_budget or 3e-4, memory_ceiling or 300
	local max_steps, steps = 1000, 0

	local start_time = LT.getTime()
	while (LT.getTime() - start_time < time_budget) and (steps < max_steps) do collectgarbage("step", 1); steps = steps + 1 end
	if collectgarbage("count") / 1024 > memory_ceiling then collectgarbage("collect") end
	if disable_otherwise then collectgarbage("stop") end
end

---------------------------------------------------------
--- Tqdm timer: Draw a timer progress bar on screen
---------------------------------------------------------
function M.tqdm_timer(gm, _label, _next, progress)
	progress = progress or 0
	gm.LOADING = gm.LOADING or { font = gm.g_fonts[1].FONT }

	local realw, realh = LW.getMode()
	LG.setCanvas();                     LG.push()
	LG.setShader();                 	LG.clear(0, 0, 0, 1)
	LG.setColor(0.6, 0.8, 0.9, 1)
	if progress > 0 then LG.rectangle("fill", realw/2 - 150, realh/2 - 15, progress*300, 30, 5) end

	LG.setColor(1, 1, 1, 1);            LG.setLineWidth(3)
	LG.rectangle("line", realw/2 - 150, realh/2 - 15, 300, 30, 5)

	if gm.F.verbose and not _RELEASE_MODE then LG.print("LOADING: " .. _next, realw/2 - 150, realh/2 + 40) end
	LG.pop();                       	       LG.present()
	gm.args.bt = love.timer.getTime()
end

return M
