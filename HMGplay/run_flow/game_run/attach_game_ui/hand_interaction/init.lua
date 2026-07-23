local MoveButton = require("HMGplay.run_flow.game_run.attach_game_ui.hand_interaction.move_button")

local M = {}

function M.make_move_button(gm, run) return MoveButton.make(gm, run) end

return M
