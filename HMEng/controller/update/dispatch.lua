local shared = require("HMEng.controller.update.shared")
local Card   = require("HMEng.entities.card")

local Y, N = true, false

return function(Controller)
-----------------------------------------------------------
--- Helper: post card confirm focus
-----------------------------------------------------------
local function _run_move_button(card)
    local gm  = card and card.gm
    local run = gm and gm.run_loop
    local btn = run and run.move_button
    if btn and btn.update then btn:update(0) end
    return btn and (btn.widget or btn)
end

local function _card_popup_focus_target(card)
    local move_btn = _run_move_button(card)
    if move_btn and not move_btn.REMOVED and not move_btn.disable_button then return move_btn end
    local ch = card and card.children;                       if not ch then return end
    for _, key in ipairs({ "focused_ui", "use_button", "buy_button", "buy_and_use_button" }) do
        local node = ch[key]
        if node and not node.REMOVED then return node end
    end
end

--- Helper: apply ready hover
local function _apply_ready_hover(node)
    local st = node and node.states;                         if not st then return end
    if st.focus then st.focus.can, st.focus.is = Y, Y end
    if st.hover then st.hover.can, st.hover.is = Y, Y end
    if node.hover then node.last_hovered = nil; node:hover() end
end

--- Helper: snap card popup focus
function Controller:_snap_card_popup_after_confirm(card)
    local gm = self.gm
    if not (gm and self.HID and self.HID.controller and card and card:is(Card) and card.zone == gm.hand) then return end
    local node = _card_popup_focus_target(card);              if not node then return end
    _apply_ready_hover(node)
    self.hand_btn_choice_card = card
    self.interrupt.focus = N
    self:snap_to({ node = node })
    self:_handle_controller()
end

-----------------------------------------------------------
--- Helper: dispatch click, drag, release, and hover side effects
-----------------------------------------------------------
function Controller:_dispatch_interaction_results(gm)
    local HID = self.HID
    local dr, r, c, h = self.dragging, self.released_on, self.clicked, self.hovering

    if not self.scrolled.handled then self:_handle_scroll() end
    if not c.handled then
        c.target:click()
        if self.hand_btn_choice_card and not (c.target.is and c.target:is(Card)) then self.hand_btn_choice_card = nil end
        self:_snap_card_popup_after_confirm(c.target)
        c.handled = Y
    end
    self:process_registry()

    local drtarget = dr.target
    if drtarget then drtarget:drag(self) end
    if not r.handled and dr.prev_target then self:_handle_release_on() end

    local htarget, hptarget = h.target, h.prev_target
    if     htarget  then self:_handle_hover_target(gm)
    elseif hptarget then hptarget:stop_hover() end
    if htarget and htarget == dr.target and not HID.touch then htarget:stop_hover() end
end

-----------------------------------------------------------
--- Main: update, called every game logic update frame
-----------------------------------------------------------
function Controller:update(gm, dt)
    self:_setup(gm)

    self:_update_locks_and__T(gm, dt)
    self:cull_registry()
    self:_update_cursor_state(dt)
    self:_update_button_inputs(dt)
    self:_update_cursor_targets()
    self:_snapshot_interaction_targets()
    self:_handle_cursor_press_release(gm)
    self:_handle_cursor_hover()
    self:_dispatch_interaction_results(gm)

    gm:_handle_controller_intents(self:drain_intents())
end

end
