local HandInteraction = require("HMGplay.run_flow.game_run.attach_game_ui.hand_interaction")

local M = {}

function M.make_move_button(gm, run) return HandInteraction.make_move_button(gm, run) end

return M
