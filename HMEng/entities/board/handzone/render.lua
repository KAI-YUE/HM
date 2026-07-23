local TabUtils = require("HMfns.utils.table_utils")
local Render   = require("HMfns.systems.render")

local contains = TabUtils.contains
local enqueue_drawable = Render.enqueue_drawable

local Y, N = true, false

return function (HandZone)
--------------------------------------------------
--- draw
--------------------------------------------------
--- Helper: valid_hand
local function valid_hand(card)
    local st = card.states
    local drag = st.drag
    return not drag.is
end

---___________________________________
--- main:draw
---___________________________________
function HandZone:draw()
    local gm, st = self.gm, self.states
    if not st.visible then return end

    local Tzone = { gm.deck, gm.hand, gm.play }
    if gm.VIEWING_DECK and contains(Tzone, self) then return end

    local _sc = self.cards
    self:bound_me()
    enqueue_drawable(self.t_drawable, self)

    for i = 1, #_sc do if valid_hand(_sc[i]) then _sc[i]:draw() end end
end

end
