local Y, N = true, false
local OPTIONS_ACTION_LOCKS = { frame = Y, frame_set = Y, title_page_options = Y, stroked_page_child_control = Y }

return function(Controller)
-----------------------------------------------------
--- Button Press | Release
-----------------------------------------------------
function Controller:button_press(b)    self:set_HID_flags("button"); self.pressed_buttons[b], self.held_buttons[b]  = Y, Y    end
function Controller:button_release(b)  self.held_buttons[b], self.released_buttons[b] = nil, Y end

-----------------------------
--- helpers
-----------------------------
--- Helper: find child by id
local function _find_child_by_id(node, id)
    local cfg = node and node.config
    if cfg and cfg.id == id then return node end
    for _, child in ipairs((node and node.children) or {}) do local found = _find_child_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do local found = _find_child_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do local found = _find_child_by_id(child, id); if found then return found end end
end

--- Helper: options menu active
local function _options_menu_active(gm)
    local UI = gm and gm.UI;                              if not UI then return N end
    local OM = UI.overlay_menu or (UI.title_page_options and UI.title_page_panel);   if not OM then return N end
    local root = OM.attached_panel and (OM.attached_panel.widget or OM.attached_panel)
    return _find_child_by_id(root, "opt_menu_mini_page") and Y or N
end

--- Helper: options action lock bypass
local function _options_action_lock_bypass(self)
    if self.screenwipe or (self.UI and self.UI.modal_backdrop) then return N end
    local active = N
    for key, value in pairs(self.locks or {}) do
        if value and not OPTIONS_ACTION_LOCKS[key] then return N end
        if value and (key == "title_page_options" or key == "stroked_page_child_control") then active = Y end
    end
    return active
end

--- Helper: load/save done active
local function _load_save_done_active(gm)
    local OM = gm and gm.UI and gm.UI.overlay_menu;                    if not OM then return N end
    local root = OM.attached_panel and (OM.attached_panel.widget or OM.attached_panel)
    return (_find_child_by_id(root, "load_folder_done_hint") or _find_child_by_id(root, "save_disk_done_hint")) and Y or N
end

--- Helper: load/save back hook
local function _load_save_back_hook(gm)
    local OM, Fs = gm and gm.UI and gm.UI.overlay_menu, gm and gm.Fs;   if not (OM and Fs) then return end
    if _find_child_by_id(OM.widget, "load_back_button_hint") then return Fs.load2pause_menu end
    if _find_child_by_id(OM.widget, "save_back_button_hint") then return Fs.save2pause_menu end
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
    if not target and self._modal_confirm_choices then target = self:_modal_confirm_choices() end
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
    "_handle_options_done_press_action",
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
    if self.UI and self.UI.modal_backdrop then return Y end
    if _options_menu_active(self.gm) then local Fs = self.gm and self.gm.Fs; if Fs and Fs.show_active_tab_info then Fs.show_active_tab_info(self.gm) end; return Y end
    return self:activate_secondary_action("delete")
end

--- Helper: options done press action
function Controller:_handle_options_done_press_action(button)
    if not (self:gamepad_button_matches("done", button) and (_options_menu_active(self.gm) or _load_save_done_active(self.gm))) then return N end
    self.pending_options_done_button = button
    return Y
end

--- Helper: options done release action
function Controller:_release_options_done_action(button)
    if self.pending_options_done_button ~= button then return N end
    self.pending_options_done_button = nil
    local Fs = self.gm and self.gm.Fs
    if _options_menu_active(self.gm) then if Fs and Fs.open_system_settings_confirm then Fs.open_system_settings_confirm(self.gm) end; return Y end
    if _load_save_done_active(self.gm) and Fs and Fs.quick_resume_menu then Fs.quick_resume_menu(self.gm) end
    return Y
end

--- Helper: start press action
function Controller:_handle_start_press_action(button)
    if not self:is_gamepad_start_button(button) then return N end
    if _options_menu_active(self.gm) then local Fs = self.gm and self.gm.Fs; if Fs and Fs.open_system_settings_confirm then Fs.open_system_settings_confirm(self.gm) end; return Y end
    self:emit_intent("escape")
    return Y
end

--- Helper: options cancel press action
function Controller:_handle_options_cancel_press_action(button)
    if not (self:is_gamepad_cancel_button(button) and _options_menu_active(self.gm)) then return N end
    self.pending_options_cancel_button = button
    return Y
end

--- Helper: options cancel release action
function Controller:_release_options_cancel_action(button)
    if self.pending_options_cancel_button ~= button then return N end
    self.pending_options_cancel_button = nil
    local gm, Fs = self.gm, self.gm and self.gm.Fs
    local hook = gm and gm.UI and gm.UI.title_page_options and Fs and Fs.title_page_options_back or Fs and Fs.options2pause_menu
    if hook then hook(gm) end
    return Y
end

--- Helper: confirm press action
function Controller:_handle_confirm_press_action(button) return self:_press_confirm_button(button) end

--- Helper: cancel press action
function Controller:_handle_cancel_press_action(button)
    if not self:is_gamepad_cancel_button(button) then return N end
    local gm, back_hook = self.gm, _load_save_back_hook(self.gm)
    if back_hook then back_hook(gm); return Y end
    if self.queue_R_cursor_press then self:queue_R_cursor_press() end
    local UI = self.UI
    if UI and (UI.overlay_menu or UI.title_page_options or UI.modal_backdrop) then self:emit_intent("escape") end
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

    if self:_locked() then
        if _options_action_lock_bypass(self) then
            if self:_handle_secondary_press_action(button) then return end
            if self:_handle_options_cancel_press_action(button) then self.held_button_times[button] = 0 end
        end
        return
    end
    if self.frame_buttonpress then return end
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
    
    if self._release_modal_cancel and self:_release_modal_cancel(button) then return end
    if self:_release_options_cancel_action(button) then return end
    if self:_release_options_done_action(button) then return end
    if self:_release_confirm_button(button) then return end
end

end
