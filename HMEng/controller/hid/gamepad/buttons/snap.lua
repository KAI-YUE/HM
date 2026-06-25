local Y, N = true, false

local CAMERA_SNAP_BUTTONS = { camleft = Y, camright = Y, camup = Y, camdown = Y }

return function(Controller)
-----------------------------------------------------
--- In-game snap helpers
-----------------------------------------------------
--- Helper: in game snap active
function Controller:_ingame_snap_active()
    local gm = self.gm;                                  if not (gm and gm.camera and gm.hand) then return N end
    if gm.SET and gm.SET.pause then return N end
    if self.UI and self.UI.overlay_menu then return N end
    return not (gm.stages and gm.g_stage == gm.stages.title_page)
end

--- Helper: camera snap button
function Controller:is_camera_snap_button(button) return CAMERA_SNAP_BUTTONS[button] == Y end

--- Helper: snap focused node
local function _snap_focus_node(self, node)
    if not node or node.REMOVED then return N end
    if node.states and node.states.focus then node.states.focus.can = Y end
    self.interrupt.focus = N
    self:snap_to({ node = node })
    self:_handle_controller()
    self:update_cursor()
    self:emit_intent("vibrate")
    return Y
end

--- Helper: first hand card
local function _first_hand_card(gm) local hand = gm and gm.hand; return hand and hand.cards and hand.cards[1] end

--- Helper: collect field cells
local function _field_cells(gm)
    local out, zone = {}, gm and gm.gridzone
    for r = 1, zone and zone.n_rows or 0 do for c = 1, zone.n_cols or 0 do out[#out + 1] = { row = r, col = c } end end
    return out
end

--- Helper: field start cell
local function _field_start_cell(gm)
    local pawn = gm and (gm.field_pawn or (gm.party_pawns and gm.party_pawns[1]))
    local cell = pawn and pawn.cell
    if cell and cell.row and cell.col then return { row = cell.row, col = cell.col } end
    return _field_cells(gm)[1]
end

--- Helper: clear node focus hover
local function _clear_node_focus_hover(node)
    if not node then return end
    if node.stop_hover then node:stop_hover() end
    if node.states then
        if node.states.hover then node.states.hover.is = N end
        if node.states.focus then node.states.focus.is = N end
    end
end

--- Helper: clear current focus
local function _clear_current_focus(self)
    local fc = self.focused;                                if not (fc and fc.target) then return end
    local node = fc.target
    _clear_node_focus_hover(node)
    fc.prev_target, fc.target = node, nil
end

--- Helper: clear hand focus hover
local function _clear_hand_focus_hover(gm)
    local hand = gm and gm.hand;                            if not (hand and hand.cards) then return end
    for _, card in ipairs(hand.cards) do _clear_node_focus_hover(card); if card.states and card.states.focus then card.states.focus.can = N end end
    if hand.mark_card_layout_dirty then hand:mark_card_layout_dirty() end
end

--- Helper: clear cursor hover
local function _clear_cursor_hover(self)
    local ch, h = self.cursor_hover, self.hovering
    _clear_node_focus_hover(ch and ch.target)
    _clear_node_focus_hover(h and h.target)
    if ch then ch.target = nil end
    if h then h.target = nil end
end

--- Helper: step card list
local function _step_card_list(list, current, step)
    if #list == 0 then return end
    local idx = 1
    for i, card in ipairs(list) do if card == current then idx = i; break end end
    return list[((idx - 1 + step) % #list) + 1]
end

--- Helper: clamp field cell
local function _clamp_field_cell(gm, cell)
    local zone = gm and gm.gridzone;                    if not (zone and cell) then return end
    local row = math.max(1, math.min(zone.n_rows or 1, cell.row or 1))
    local col = math.max(1, math.min(zone.n_cols or 1, cell.col or 1))
    return { row = row, col = col }
end

--- Helper: next field cell
local function _next_field_cell(self, gm, current, button)
    if not current then return _field_start_cell(gm) end
    local cell = { row = current.row or 1, col = current.col or 1 }
    local dir = self:gamepad_dpad_dir(button)
    if     dir == "L" then cell.col = cell.col - 1
    elseif dir == "R" then cell.col = cell.col + 1
    elseif dir == "U" then cell.row = cell.row - 1
    elseif dir == "D" then cell.row = cell.row + 1 end
    return _clamp_field_cell(gm, cell)
end

--- Helper: handle field focus snap
function Controller:_snap_field_focus(dir)
    local gm = self.gm;                                    if not gm then return N end
    self.navigate_field, self.gamepad_focus_scope = Y, "field"
    _clear_hand_focus_hover(gm)
    _clear_cursor_hover(self)
    local current = dir == 0 and _field_start_cell(gm) or self.field_focus_cell or _field_start_cell(gm)
    self.field_focus_cell = _next_field_cell(self, gm, current, dir)
    if gm.gridzone and gm.gridzone.mark_focus_projection_dirty then gm.gridzone:mark_focus_projection_dirty() end
    _clear_current_focus(self)
    return self.field_focus_cell and Y or N
end

--- Helper: handle hand focus snap
function Controller:_snap_hand_focus(step)
    local gm, fct = self.gm, self.focused and self.focused.target
    local hand = gm and gm.hand;                           if not (hand and hand.cards and hand.cards[1]) then return N end
    self.navigate_field, self.gamepad_focus_scope = N, "hand"
    self.field_focus_cell = nil
    if not (fct and fct.zone == hand) then return _snap_focus_node(self, _first_hand_card(gm)) end
    return _snap_focus_node(self, _step_card_list(hand.cards, fct, step or 0))
end

--- Helper: camera snap offset
function Controller:_update_camera_snap_offset()
    local gm, held = self.gm, self.held_buttons or {}
    local cam = gm and gm.camera;                         if not (cam and cam.active and cam.target) then return N end
    local dist = (gm.card_w or 1) * 2.4
    local x = (held.camright and dist or 0) - (held.camleft and dist or 0)
    local y = (held.camdown and dist or 0) - (held.camup and dist or 0)
    self.gamepad_camera_snap = self.gamepad_camera_snap or { x = 0, y = 0 }
    self.gamepad_camera_snap.x, self.gamepad_camera_snap.y = x, y
    if cam.set_target_offset then cam:set_target_offset(x, y) else cam.target_offset.x, cam.target_offset.y = x, y end
    return Y
end

--- Helper: handle camera snap button
function Controller:_handle_camera_snap_button(button)
    if not self:is_camera_snap_button(button) or not self:_ingame_snap_active() then return N end
    self.held_button_times[button] = self.held_button_times[button] or 0
    self:_update_camera_snap_offset()
    return Y
end

--- Helper: handle in-game dpad snap
function Controller:_handle_ingame_dpad_snap(button)
    if not self:_ingame_snap_active() or not self:is_gamepad_dpad_button(button) then return N end
    if self.navigate_field or self.gamepad_focus_scope == "field" then return self:_snap_field_focus(button) end
    local dir = self:gamepad_dpad_dir(button);              if dir ~= "L" and dir ~= "R" then return N end
    self.gamepad_focus_scope = "hand"
    return self:_snap_hand_focus(dir == "L" and -1 or 1)
end

--- Helper: cancel hand button choice
function Controller:cancel_hand_btn_choice()
    local card, hand = self.hand_btn_choice_card, self.hand
    if not card then return N end
    if hand and hand.remove_from_highlighted and card.highlighted then hand:remove_from_highlighted(card, Y) end
    self.hand_btn_choice_card = nil
    local fc = self.focused
    if fc and fc.target then
        local node = fc.target
        _clear_node_focus_hover(node)
        fc.prev_target, fc.target = node, card
        if card and card.states and card.states.focus then card.states.focus.can, card.states.focus.is = Y, Y end
        if card and card.states and card.states.hover then card.states.hover.can, card.states.hover.is = Y, Y end
    end
    if self.HID and self.HID.controller then self:update_cursor() end
    if hand and hand.mark_card_layout_dirty then hand:mark_card_layout_dirty() end
    return Y
end

--- Helper: cancel hand button choice input
function Controller:_cancel_hand_btn_choice_input(button)
    if not (self.is_gamepad_cancel_button and self:is_gamepad_cancel_button(button)) then return N end
    if self.held_button_times then self.held_button_times[button] = nil end
    if self.queue_R_cursor_press then self:queue_R_cursor_press() else self:cancel_hand_btn_choice() end
    return Y
end

--- Helper: handle hand button choice lock
function Controller:_handle_hand_btn_choice_input(button)
    local active = self.hand_btn_choice_card
    if not active then return N end
    if self:_cancel_hand_btn_choice_input(button) then return Y end
    if self:is_gamepad_dpad_button(button) then return Y end
    return N
end

end
