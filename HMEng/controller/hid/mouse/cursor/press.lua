local Common = require("HMEng.controller.hid.mouse.cursor.common")
local PointerGrid = require("HMEng.controller.debug.pointer_grid")

local Y, N = true, false

local M = {}

---____________________________
--- main: install
---______________________________________
function M.install(Controller)
    function Controller:queue_L_cursor_press(x, y)
        PointerGrid.capture_click(self, x, y)
        if self:_locked() then return end
        if self.g_state == self.g_states.splash then self:key_press("escape") end
        self.L_cursor_queue = { x = x, y = y }
    end

    function Controller:queue_R_cursor_press()
        if self:_locked() then return end
        if self.cancel_hand_btn_choice and self:cancel_hand_btn_choice() then return end
        local hand, play, stop_use = self.hand, (self.play and #self.play.cards > 0), self.stop_use and self.stop_use > 0
        if self.SET.pause or not hand or not hand.highlighted[1] then return end
        if play or stop_use then return end
        hand:unhighlight_all()
    end

    function Controller:L_cursor_press(x, y)
        if self:_locked() then return end
        if self.UI and self.UI.title_page_press_any then self.frame_buttonpress = Y; self:emit_intent("title_page_press_any"); return end

        local cpos,   cdown   = self.cursor_position, self.cursor_down
        local _T,     R       = self._T,              self._room
        local chover, rcfg    = self.cursor_hover,    self.rcfg
        local norm            = rcfg.tile_size*rcfg.tile_scale

        x,             y             = x or cpos.x, y or cpos.y
        cdown.T,       cdown.time    = { x = x/norm, y = y/norm }, _T.game_s
        cdown.handled, cdown.target  = N, nil
        self.is_cursor_down = Y

        local press_node = chover.target or self.hovering.target or self.focused.target
        if not Common.gamepad_scope_allows_node(self, press_node) then press_node = nil end
        if press_node then
            local drag_node = press_node:can_drag()
            cdown.target = press_node.states.click.can and press_node or (drag_node == Y and press_node or drag_node)
        end
        if not cdown.target then cdown.target = R end
    end

    function Controller:L_cursor_release(x, y)
        if self:_locked() then return end

        local cpos,  cup   = self.cursor_position, self.cursor_up
        local R,     rcfg  = self._room,           self.rcfg
        local norm,  _T    = rcfg.tile_size*rcfg.tile_scale, self._T

        x, y = x or cpos.x, y or cpos.y
        cup.T,       cup.time    = { x = x / norm, y = y / norm }, _T.game_s
        cup.handled, cup.target  = N, nil
        self.is_cursor_down = N

        cup.target = self.hovering.target or self.focused.target
        if not cup.target then cup.target = R end
    end
end

return M
