local Common = require("HMEng.controller.hid.mouse.cursor.common")

local N = false

local M = {}

---____________________________
--- main: install
---______________________________________
function M.install(Controller)
    function Controller:_handle_gamepad_hover(HID, fct, chover)
        local follows_focus = HID.dpad or (HID.axis_cursor and fct.states.collide.is)
        if follows_focus and Common.modal_cursor_allows_node(self, fct) and not Common.field_nav_blocks_hand_node(self, fct) and Common.gamepad_scope_allows_node(self, fct) then chover.target = fct; return end
        for _, v in ipairs(self.collision_list) do if v.states.hover.can and Common.modal_cursor_allows_node(self, v) and not Common.field_nav_blocks_hand_node(self, v) and Common.gamepad_scope_allows_node(self, v) then chover.target = v; break end end
    end

    function Controller:_handle_general_hover(HID, chover)
        for _, v in ipairs(self.collision_list) do local states = v.states; if states.hover.can and (not states.drag.is or HID.touch) and Common.modal_cursor_allows_node(self, v) and not Common.field_nav_blocks_hand_node(self, v) then chover.target = v; break end end
    end

    function Controller:set_cursor_hover()
        local chover, C,      dr  = self.cursor_hover, self.p_cursor, self.dragging
        local HID,    R,      fc  = self.HID,          self._room,    self.focused
        local fct,    _T, cT      = fc.target,         self._T,       C.T

        chover.T, chover.time = chover.T or {}, _T.game_s
        local hT, locked = chover.T, self:_locked()

        if Common.field_nav_blocks_hand_node(self, self.hovering.target) then Common.clear_hover_node(self.hovering.target); self.hovering.target = nil end
        if not Common.gamepad_scope_allows_node(self, self.hovering.target) then Common.clear_hover_node(self.hovering.target); self.hovering.target = nil end
        if not Common.modal_cursor_allows_node(self, self.hovering.target) then Common.clear_hover_node(self.hovering.target); self.hovering.target = nil end
        if not Common.gamepad_scope_allows_node(self, chover.target) then Common.clear_hover_node(chover.target); chover.target = nil end
        if not Common.modal_cursor_allows_node(self, chover.target) then Common.clear_hover_node(chover.target); chover.target = nil end
        hT.x,               hT.y           = cT.x, cT.y
        chover.prev_target, chover.target  = chover.target, nil

        if self.interrupt.focus or locked or self.CFOCUS then chover.target = R; return end
        if HID.controller and fct and fct.states.hover.can then self:_handle_gamepad_hover(HID, fct, chover) else self:_handle_general_hover(HID, chover) end

        if not chover.target or (dr.target and not HID.touch) then chover.target = R end
        if chover.target ~= chover.prev_target then chover.handled = N end
    end
end

return M
