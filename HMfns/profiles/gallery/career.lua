local M = {}

-----------------------------------------
--- Update Career
-----------------------------------------
function M.update_career(gm, stat, mod)
    local game, P = gm.GAME, gm.g_profile
	if game.seeded or game.challenge then return end

	local prof = P[gm.SET.profile]
    local career = prof.career_stats
	career[stat] = career[stat] or 0
	career[stat] = career[stat] + (mod or 0)
	if gm.save_settings then gm:save_settings() end
end

return M