local HMPanel = require("HMEng.ui_actors.hm_panel")
local I18N    = require("HMfns.utils.format.i18n_utils")
local Attach  = require("HMEng.ui_actors.common.actor_attachment")
local Data    = require("HMui.menu.data.game_run.hand_interaction.move_button")
local Helpers = require("HMGplay.run_flow.game_run.helpers")
local Turns   = require("HMGplay.run_flow.game_run.turns")

local i18n, interpolate = I18N.i18n, I18N.interpolate

local Y, N = true, false
local TEXT_CACHE_KEYS = {
    "prev_raw_text",            -- last raw cfg.text seen by text update
    "prev_text",                -- last rendered text after wrap/reveal
    "prev_text_drawable_key",   -- cache key for main text drawable
    "text_fit_drawable_key",    -- cache key for reveal fit drawable
    "text_drawable",            -- main single-font text drawable
    "text_drawable_runs",       -- main multi-font text drawable runs
    "text_fit_drawable",        -- full text drawable used by reveal fit
    "text_fit_drawable_runs",   -- multi-font reveal fit drawable runs
}

local M = {}

-----------------------------
--- text
----------------------------------
--- Helper: clear text cache
local function _clear_text_cache(cfg) for _, key in ipairs(TEXT_CACHE_KEYS) do cfg[key] = nil end end

--- Helper: move button text
local function _move_button_text(run)
    local card = run.gm.hand and run.gm.hand.highlighted[1]
    local value = card and Helpers.card_value(card) or 0
    return interpolate(i18n(run.gm, Data.label_key, Data.label_pack), { value })
end

--- Helper: set move button text
local function _set_move_button_text(widget, text)
    local label_id = Data.label_id()
    for _, child in ipairs(widget.children or {}) do
        local cfg = child.config
        if cfg and cfg.id == label_id then
            cfg.text, cfg.lang = text, widget.gm and widget.gm.selected_lang
            _clear_text_cache(cfg)
        end
    end
end

-----------------------------
--- placement
----------------------------
--- Helper: card visual transform
local function _card_anchor_T(card) return (card and card.VT) or (card and card.T) end

local function _place_move_button(panel, card, text)
    if not (panel and card) then return end
    Attach.attach(panel, card, { slot = "use_button" })
    if Data.relayout then return Data.relayout(panel, text, _card_anchor_T(card), panel.gm and panel.gm.selected_lang) end
    Attach.hard_set_panel_tree(panel, Data.anchor_T(_card_anchor_T(card), text, panel.gm and panel.gm.selected_lang))
end

-----------------------------
--- state
----------------------------
--- Helper: player may move
local function _player_may_move(run) return not (run.battle and run.battle.active) and run.turn == 1 and not run.busy end

--- Helper: move button visible
local function _move_button_visible(run, card) return _player_may_move(run) and card ~= nil end

-----------------------------
--- make_move_button
----------------------------------
function M.make(gm, run)
    local panel = HMPanel(gm, Data.prototype({
        label = _move_button_text(run),
        hook_fn = function()
            Turns.play_selected_card(run)
            return Y
        end,
    }))
    local card = gm.hand and gm.hand.highlighted[1]
    if card then _place_move_button(panel, card, _move_button_text(run)) end

    local base_update = panel.update
    panel.update = function(self, dt)
        if base_update then base_update(self, dt) end
        local card    = gm.hand and gm.hand.highlighted[1]
        local plan    = Helpers.refresh_player_move_options(run)
        local visible = _move_button_visible(run, card)
        local enabled = visible and plan and #plan.endpoints > 0
        self.states.visible = visible
        local text = _move_button_text(run)
        if visible then _place_move_button(self, card, text) else Attach.detach(self) end
        if self.widget then
            self.widget.states.visible = visible
            self.widget.disable_button = not enabled
            _set_move_button_text(self.widget, text)
        end
    end
    return panel
end

return M
