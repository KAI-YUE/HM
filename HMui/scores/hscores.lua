-- -- local UIPanel     = require("HMEng.ui_actors.ui_panel")     = require("HMEng.ui_actors.ui_panel") require("HMEng.ui_actors.ui_panel")

local M = {}

function M.high_score_alert(gm, e)
	if not e or not e.config or not e.config.id then return end
	if e.children and e.children.alert then return end

	local rs = gm.GAME and gm.GAME.round_scores
	local score = rs and rs[e.config.id]
	if not (score and score.high_score) then return end

	-- create + attach alert
	local alert = UIPanel(gm, {
		definition = create_UIPanel_card_alert(gm, {
			no_bg = true,
			text = gm.Fs.localize(gm, "k_high_score_ex"),
			scale = 0.3
		}),
		config = {
			instance_type = "ALERT",
			align = "tri",
			offset = { x = 0.3, y = -0.18 },
			major = e,
			parent = e
		}
	})

	alert.states.collide.can = false
	e.children = e.children or {}
	e.children.alert = alert
end


--- High scores overlay
function M.high_scores(gm)
	gm.SET.pause = true
	gm.Fs.overlay_menu(gm, { definition = create_UIPanel_high_scores(gm) })
end


--- Wait for high scores (async update)
function M.wait_for_high_scores(gm, e)
	if gm.args.HIGH_SCORE_RESPONSE then
		e.config.object:remove()
		e.config.object = UIPanel(gm, {
			definition = create_UIPanel_high_scores_filling(gm, gm.args.HIGH_SCORE_RESPONSE),
			config = {offset = {x=0,y=0}, align = 'cm', parent = e}
		})
		gm.args.HIGH_SCORE_RESPONSE = nil
	end
end


return M