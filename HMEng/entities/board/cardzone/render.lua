-- local UIPanel     = require("HMEng.ui_actors.ui_panel")    = require("HMEng.ui_actors.ui_panel")
local TabUtils   = require("HMfns.utils.table_utils")
local Render, C  = require("HMfns.systems.render"), require("HMfns.animate.color.color_const")
local CUtils     = require("HMfns.animate.color.color_utils")
local I18N       = require("HMfns.utils.format.i18n_utils")

local i18n, set_alpha  = I18N.i18n, CUtils.set_alpha
local enqueue_drawable = Render.enqueue_drawable
local push, contains   = table.insert, TabUtils.contains
local abs = math.abs

local cw, cc, ck = C.WHITE, C.CLEAR, C.BLACK
local Y, N       = true, false

return function (CardZone)
------------------------------------------------------------------
--- draw 
-----------------------------------------------------------------
--- Helper: valid card
local function _valid_card(card)
    local st = card.states
    local drag, focus = st.drag, st.focus
    return not drag.is and not focus.is
end

--______________________
--- Main 
--______________________
function CardZone:draw()
    local gm, st = self.gm, self.states;          if not st.visible then return end 
    local Tzone  = { gm.deck, gm.hand, gm.play }; if gm.VIEWING_DECK and contains(Tzone, self) then return end

    local args, cfg, state = self.args, self.config, gm.t_interrupt or gm.g_state
    local type, _sc  = cfg.type, self.cards

    self:bound_me();              enqueue_drawable(self.t_drawable, self)
    if type == "discard" then for i = 1, #_sc do if _valid_card(_sc[i]) then _sc[i]:draw() end end end
end

end
