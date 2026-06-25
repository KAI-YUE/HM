local ta, Y, N = "after", true, false

local M = {}

---------------------------------------------------------
--- Debug functions and related Helpers 
---------------------------------------------------------
local function _run(gm) return gm.g_stage == gm.stages.run_game end

local function _lose(gm)
    if not _run(gm) then return end
    gm.g_state = gm.g_states.game_over
    gm.state_comp = N
end

-- ===== Debug actions =====
function M.DT_add_money(gm)    if _run(gm) then gm.Fs.add_money(gm, 10) end  end
function M.DT_rich(gm)         if _run(gm) then gm.Fs.add_money(gm, 400) end  end
function M.DT_alert(gm)        gm.Fs.enqueue_alert(gm, "cheat") end
function M.DT_win_game(gm)     if _run(gm) then gm.Fs.victory(gm) end end
function M.DT_lose_game(gm)    _lose(gm) end

return M