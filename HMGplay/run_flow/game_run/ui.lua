local HMPanel     = require("HMEng.ui_actors.hm_panel")
local I18N        = require("HMfns.utils.format.i18n_utils")
local C           = require("HMfns.animate.color.color_const")
local Helpers     = require("HMGplay.run_flow.game_run.helpers")
local Turns       = require("HMGplay.run_flow.game_run.turns")

local i18n, interpolate = I18N.i18n, I18N.interpolate

local Y = true

local M = {}

-----------------------------
--- make_move_button
----------------------------------
--- Helper: move button text
local function _move_button_text(run)
    local card = run.gm.hand and run.gm.hand.highlighted[1]
    local value = card and Helpers.card_value(card) or 0
    local text  = i18n(run.gm, "board_state.go_steps", "gameplay")
    return interpolate(text, { value })
end

--- Helper: make move button
local function _make_move_button(gm, run)
    local hand = gm.hand
    local hT   = hand and hand.T or { x = 8, y = 9, w = 6 }
    local panel = HMPanel(gm, {
        style      = "paint_rect",
        T          = { x = hT.x - 2.45, y = hT.y + 0.15, w = 2.2, h = 0.8 },
        text       = _move_button_text(run),
        text_scale = 0.46,
        text_color = C.UI.TEXT_LIGHT,
        fill_color = C.ORANGE,
        button     = Y,
        can_hover  = Y,
        can_click  = Y,
        hook_fn    = function()
            Turns.play_selected_card(run)
            return Y
        end,
    })

    local base_update = panel.update
    panel.update = function(self, dt)
        if base_update then base_update(self, dt) end
        local plan    = Helpers.refresh_player_move_options(run)
        local visible = not (run.battle and run.battle.active) and run.turn == 1 and not run.busy and gm.hand and gm.hand.highlighted[1] ~= nil
        local enabled = visible and plan and #plan.endpoints > 0
        self.states.visible = visible
        if self.widget then
            self.widget.states.visible = visible
            self.widget.disable_button = not enabled
            self.widget.config.text = _move_button_text(run)
        end
    end
    panel:update(0)
    return panel
end

M.make_move_button = _make_move_button

return M
