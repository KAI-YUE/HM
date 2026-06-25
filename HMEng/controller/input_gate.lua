local M = {}

local _max = math.max

local Y, N = true, false
-------------------------------------------------------
--- Suspend Interaction 
-------------------------------------------------------
function M.suspend_interaction(gm)
    local game = gm.GAME
	game.STOP_USE = (game.STOP_USE or 0) + 1
	M._dec(gm, 6)
end

function M._dec(gm, _c)
    local EM = gm.E_MANAGER
	if _c > 0 then EM:enqueue_event({ blocking = N, no_delete = Y, func = function() return M._dec(gm, _c - 1) end })
    else           EM:enqueue_event({ blocking = N, no_delete = Y, func = function() gm.GAME.STOP_USE = _max((gm.GAME.STOP_USE or 0) - 1, 0); return true end }) end
    return true
end

return M