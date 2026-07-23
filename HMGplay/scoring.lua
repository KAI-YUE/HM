local M = {}

-------------------------------------------------
--- High score 
-------------------------------------------------
function M.update_high_score(gm, score, amt)
	if not amt or type(amt) ~= "number" then return end

    local game, SET, P  = gm.GAME, gm.SET, gm.g_profile
    local rscores       = game.round_scores
    local seeded, _f    = game.seeded, math.floor

    if seeded then return end
	if rscores[score] and _f(amt) > rscores[score].amt then rscores[score].amt = _f(amt) end

	local prof    = P[SET.profile]
    local hscores = prof.high_scores
	if not hscores[score] or _f(amt) <= hscores[score].amt then return end -- early bail out

    if rscores[score] then rscores[score].high_score = true end
    hscores[score].amt = _f(amt)
    if gm.save_settings then gm:save_settings() end
end


return M