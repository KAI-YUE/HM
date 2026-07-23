-- -- local UIPanel     = require("HMEng.ui_actors.ui_panel")     = require("HMEng.ui_actors.ui_panel") require("HMEng.ui_actors.ui_panel")

local Y, N = true, false

return function (GMgr)

function GMgr:update_hand_played(dt)
    if self.buttons then self.buttons:remove(); self.buttons = nil end
    if self.shop then self.shop:remove(); self.shop = nil end

    if not self.state_comp then
        self.state_comp = Y
        self.E_MANAGER:enqueue_event({
            trigger = "immediate",
            func = function()
        if self.GAME.chips - self.GAME.blind.chips >= 0 or self.GAME.current_round.hands_left < 1 then
            self.g_state = self.g_states.new_round
        else
            self.g_state = self.g_states.draw_hand
        end
        self.state_comp = false
        return Y
        end
        })
    end
end

-----------------------------
--- update_draw_to_hand
----------------------------------
function GMgr:update_draw_to_hand(dt)
    if self.buttons then self.buttons:remove(); self.buttons = nil end

    if self.state_comp then return end 
    self.state_comp = Y
    self.E_MANAGER:enqueue_event({ func = function() return self.Fs.draw_deck2hand(self) end })
end

-----------------------------
--- update new round 
----------------------------------
function GMgr:update_new_round(dt)
    if self.buttons then self.buttons:remove(); self.buttons = nil end
    if self.shop then self.shop:remove(); self.shop = nil end

    if not self.state_comp then self.state_comp = Y; end_round() end
end

end