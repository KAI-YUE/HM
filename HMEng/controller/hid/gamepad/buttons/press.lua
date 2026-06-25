local Y, N = true, false

return function(Controller)
-----------------------------------------------------
--- Button Press | Release
-----------------------------------------------------
function Controller:button_press(b)    self.pressed_buttons[b], self.held_buttons[b]  = Y, Y    end
function Controller:button_release(b)  self.held_buttons[b], self.released_buttons[b] = nil, Y end

--- Helper: options menu active
local function _options_menu_active(gm)
    local UI = gm and gm.UI;                              if not UI then return N end
    local OM = UI.overlay_menu or (UI.title_page_options and UI.title_page_panel);   if not OM then return N end
    local mini = OM.attached_panel and (OM.attached_panel.widget or OM.attached_panel)
    local cfg = mini and mini.config
    return cfg and cfg.id == "opt_menu_mini_page"
end

--- Helper: focused click target
function Controller:_focused_click_target()
    local fct = self.focused and self.focused.target;       if not (fct and self:is_focusable(fct)) then return end
    local click = fct.states and fct.states.click;           if not (click and click.can) then return end
    return fct
end

--- Helper: press confirm
function Controller:_press_confirm_button(button)
    if not self:is_gamepad_confirm_button(button) then return N end
    local target = self:_focused_click_target()
    if target then
        local x, y = target:put_focused_cursor()
        self.cursor_hover.target, self.hovering.target = target, target
        self:L_cursor_press(x, y)
        return Y
    end
    self:L_cursor_press()
    return Y
end

--- Helper: release confirm
function Controller:_release_confirm_button(button)
    if not self:is_gamepad_confirm_button(button) then return N end
    if not self.cursor_down.target then return N end
    local target = self.cursor_down.target
    if target and not target.REMOVED and target.put_focused_cursor then local x, y = target:put_focused_cursor(); self:L_cursor_release(x, y); return Y end
    self:L_cursor_release()
    return Y
end

--- Helper: title page auto snap
function Controller:_title_page_button_auto_snap(button)
    local gm = self.gm;                              if not (gm and gm.stages and gm.g_stage == gm.stages.title_page) then return N end
    if self:is_gamepad_confirm_button(button) or self:is_gamepad_cancel_button(button) then return N end
    if not (self.debug_gamepad_mode or (self.GAMEPAD and self.GAMEPAD.object)) then return N end
    if self.focused.target and self:is_focusable(self.focused.target) then return N end
    return self:auto_snap_focus()
end

-----------------------------------------------------
--- Press pipeline
-----------------------------------------------------
local PRESS_PIPELINE = {
    "_handle_hand_btn_choice_input",
    "_handle_scope_switch_press_action",
    "_handle_ingame_dpad_snap",
    "_handle_focused_press_input",
    "_handle_secondary_press_action",
    "_handle_start_press_action",
    "_handle_options_cancel_press_action",
    "_handle_confirm_press_action",
    "_handle_cancel_press_action",
    "_handle_nav_press_action",
}

--- Helper: focused press input
function Controller:_handle_focused_press_input(button, dt) return self:capture_focused_input(button, "press", dt) end

--- Helper: secondary press action
function Controller:_handle_secondary_press_action(button)
    if not self:is_gamepad_secondary_button(button) then return N end
    return self:activate_secondary_action("delete")
end

--- Helper: start press action
function Controller:_handle_start_press_action(button)
    if not self:is_gamepad_start_button(button) then return N end
    if _options_menu_active(self.gm) then self:emit_intent("opt_done"); return Y end
    self:emit_intent("escape")
    return Y
end

--- Helper: options cancel press action
function Controller:_handle_options_cancel_press_action(button)
    if not (self:is_gamepad_cancel_button(button) and _options_menu_active(self.gm)) then return N end
    self:emit_intent("opt_back")
    return Y
end

--- Helper: confirm press action
function Controller:_handle_confirm_press_action(button) return self:_press_confirm_button(button) end

--- Helper: cancel press action
function Controller:_handle_cancel_press_action(button)
    if not self:is_gamepad_cancel_button(button) then return N end
    if self.queue_R_cursor_press then self:queue_R_cursor_press() end
    self:emit_intent("escape")
    return Y
end

--- Helper: scope switch press action
function Controller:_handle_scope_switch_press_action(button)
    local action = self:gamepad_scope_action(button);         if not (action and self:_ingame_snap_active()) then return N end
    if action == "field" then self.navigate_field, self.gamepad_focus_scope = Y, "field"; return self:_snap_field_focus(0) end
    if action == "hand"  then self.navigate_field, self.gamepad_focus_scope = N, "hand";  return self:_snap_hand_focus(0) end
    return N
end

--- Helper: nav press action
function Controller:_handle_nav_press_action(button)
    local dir = self:gamepad_dpad_dir(button);                if not dir then return N end
    self.interrupt.focus = N
    self:navigate_focus(dir)
    return Y
end

--- Helper: run press pipeline
function Controller:_run_button_press_pipeline(button, dt)
    for _, name in ipairs(PRESS_PIPELINE) do if self[name](self, button, dt) then return Y end end
    return N
end

-----------------------------------------------------
--- Button press update
-----------------------------------------------------
function Controller:button_press_update(button, dt)
    if self:_title_page_button_auto_snap(button) then return end
    if self:_handle_camera_snap_button(button) then return end

    if self.UI and self.UI.title_page_press_any then
        self.frame_buttonpress = Y
        self:emit_intent("title_page_press_any")
        return
    end

    if (self:_locked() or self.frame_buttonpress) then return end
    self.frame_buttonpress          = Y
    self.held_button_times[button]  = 0
    if self.navigate_field then self.gamepad_focus_scope = "field" end

    self:_run_button_press_pipeline(button, dt)
end

-----------------------------------------------------
--- Button hold update
-----------------------------------------------------
function Controller:button_hold_update(button, dt)
    if (self:_locked() or self.frame_buttonpress) then return end
    if self:_handle_camera_snap_button(button) then return end
    self.frame_buttonpress = Y

    local htimes = self.held_button_times
    if htimes[button] then htimes[button] = htimes[button] + dt; self:capture_focused_input(button, "hold", dt) end
    
    if not self:is_gamepad_dpad_button(button) or self.no_holdcap then return end
    self.repress_timer = self.repress_timer or 0.3;          if not (htimes[button] and htimes[button] > self.repress_timer) then return end

    self.repress_timer, htimes[button] = 0.1, 0
    self:button_press_update(button, dt)
end

-----------------------------------------------------
--- Button release update
-----------------------------------------------------
function Controller:button_release_update(button)
    if self:is_camera_snap_button(button) then self.held_button_times[button] = nil; self:_update_camera_snap_offset(); return end
    local htimes = self.held_button_times;              if not htimes[button] then return end
    self.repress_timer, htimes[button] = 0.3, nil
    if self:_release_confirm_button(button) then return end
end

end
