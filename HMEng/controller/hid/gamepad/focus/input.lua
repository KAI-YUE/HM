local SliderOps    = require("HMEng.ui_actors.hm_widget.ops.slider")
local ConfirmPopup = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup")
local Card         = require("HMEng.entities.card")

local push = table.insert
local _nudge_slider_by_percent = SliderOps.nudge_by_percent

local Y, N = true, false

return function(Controller)
----------------------------------------------------------
--- is focusable
----------------------------------------------------------
function Controller:is_focusable(focus_target)
    local cfg = focus_target and focus_target.config;                if not cfg or focus_target.REMOVED or focus_target.disable_button then return N end
    local st = focus_target.states;                                  if st and st.visible == N then return N end

    local gm = self.gm
    if self.navigate_field and gm and gm.hand and focus_target.zone == gm.hand then return N end
    if cfg.gamepad_focus == N then return N end
    if focus_target.is and focus_target:is(Card) then return Y end
    local p = focus_target.parent

    while p do
        local fargs = p.config and p.config.focus_args
        if fargs and fargs.type and fargs.type:match("_row$") then return N end
        p = p.parent
    end

    return cfg.focus_args or cfg.button or cfg.button_UI or cfg.can_click == Y
end

----------------------------------------------------------
--- Capture focused input
----------------------------------------------------------
--- Helper: find child by id
local function _find_child_by_id(node, id)
    local cfg = node and node.config
    if cfg and cfg.id == id then return node end
    for _, child in ipairs((node and node.children) or {}) do local found = _find_child_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do local found = _find_child_by_id(child, id); if found then return found end end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do local found = _find_child_by_id(child, id); if found then return found end end
end

--- Helper: active options panel
local function _active_options_panel(UI)
    local panel = UI and (UI.overlay_menu or (UI.title_page_options and UI.title_page_panel));     if not panel then return end
    local mini = panel.attached_panel and (panel.attached_panel.widget or panel.attached_panel)
    local cfg  = mini and mini.config;                                                            if cfg and cfg.id == "opt_menu_mini_page" then return panel end
end

--- Helper: handle shoulder buttons
function Controller:_handle_shoulder_btns(fc, input_type, b)
    if self.navigate_field then return N end
    local _shoulder = (b == "leftshoulder" or b == "rightshoulder");                          if self.screen_keyboard or not _shoulder or input_type ~= "press" then return N end
    local opt_panel = _active_options_panel(self.UI)
    local OM = opt_panel or (self.UI and self.UI.overlay_menu);                                if not OM then return N end
    local root = OM.UIRoot or OM.widget
    local tab_shoulders = _find_child_by_id(root, "tab_shoulders")
    local cycle_shoulders = _find_child_by_id(root, "cycle_shoulders")
    if tab_shoulders and fc then fc.target = tab_shoulders
    elseif cycle_shoulders and cycle_shoulders.children and fc then fc.target = cycle_shoulders.children[1] end
    local gm = self.gm
    if OM == opt_panel then self:emit_intent("opt_tab_step", { step = b == "rightshoulder" and 1 or -1 }); return Y end
    return Y
end

--- Helper: click child
local function _click_child(node, id) local child = _find_child_by_id(node, id); if child and child.click then child:click(); return Y end end

--- Helper: hover child
local function _hover_child(child, force)
    if not child then return N end
    local st = child.states
    local fst = st and st.focus;                         if fst then fst.can, fst.is = Y, Y end
    if force then child.last_hovered = nil end
    if child.hover then child:hover() end
    return Y
end

--- Helper: clear hover child
local function _clear_hover_child(child)
    local hst = child and child.states and child.states.hover;       if not hst then return end
    if hst.is and child.stop_hover then child:stop_hover(); return end
    hst.is = N
end

--- Helper: modal confirm choices
local function _modal_confirm_choices(self)
    local popup = self.UI and self.UI.modal_backdrop and self.UI.modal_backdrop.owner;       if not popup or popup.REMOVED then return end
    local yes, no
    for _, child in ipairs((popup.widget and popup.widget.children) or {}) do
        local id = child.config and child.config.id
        if id and id:match("_yes$") then yes = child elseif id and id:match("_no$") then no = child end
    end
    return yes, no
end

--- Helper: focus modal confirm choice
function Controller:_focus_modal_confirm_choice(b, input_type)
    if input_type ~= "press" or (b ~= "dpleft" and b ~= "dpright") then return N end
    local yes, no = _modal_confirm_choices(self);                  if not (yes and no) then return N end
    local target = b == "dpleft" and yes or no;                    if not self:is_focusable(target) then return N end
    self.interrupt.focus = N
    self:snap_to({ node = target })
    self:update_cursor()
    return Y
end

--- Helper: cancel modal confirm
function Controller:_cancel_modal_confirm(b, input_type)
    if input_type ~= "press" or not ((self.is_gamepad_cancel_button and self:is_gamepad_cancel_button(b)) or (not self.is_gamepad_cancel_button and (b == "b" or b == "x"))) then return N end
    return ConfirmPopup.cancel_active_popup(self.gm) and Y or N
end

--- Helper: cycle widget
function Controller:_cycle_widget(eb, b, fct)
    local idx = nil
    if     ((eb and b == "leftshoulder")  or (not eb and b == "dpleft"))  then idx = 1
    elseif ((eb and b == "rightshoulder") or (not eb and b == "dpright")) then idx = 3 end
    if idx then fct.children[idx]:click(); return Y end
end

--- Helper: tab widget select
function Controller:_tab_widget_select(choices, k, next_i)
    choices[next_i]:click()
    self:snap_to({ node = choices[next_i] })
    self:update_cursor()
    return Y
end

--- Helper: _tab_widget_left
function Controller:_tab_widget_left(choices, k, args)
    local next_i = k ~= 1 and (k - 1) or #choices
    if args.no_loop and next_i > k then return N end
    return self:_tab_widget_select(choices, k, next_i)
end

--- Helper: _tab_widget_right
function Controller:_tab_widget_right(choices, k, args)
    local next_i = k ~= #choices and (k + 1) or 1
    if args.no_loop and next_i < k then return N end
    return self:_tab_widget_select(choices, k, next_i)
end

--- Helper: _tab_widget
function Controller:_tab_widget(fct, eb, b)
    local args                    = fct.config.focus_args or {}
    local proto_choices, choices  = fct.UIPanel:get_group(nil, fct.children[1].children[1].config.group), {}
    for _, v in ipairs(proto_choices) do local vcfg = v.config; if vcfg.choice and vcfg.button then push(choices, v) end end
    
    for k, v in ipairs(choices) do
        if not v.config.chosen then goto continue end
        if     (eb and b == "leftshoulder")  or (not eb and b == "dpleft")  then if self:_tab_widget_left(choices, k, args) then return Y end
        elseif (eb and b == "rightshoulder") or (not eb and b == "dpright") then if self:_tab_widget_right(choices, k, args) then return Y end end
        ::continue::
    end
    return N
end

--- Helper: _slider_widget_left
function Controller:_slider_widget_left(fct, input_type, dt, hbt)
    self.no_holdcap = Y
    local knob = fct.children[1];     _hover_child(knob, input_type == "press")
    if input_type == "hold" and hbt["dpleft"] > 0.2 then _nudge_slider_by_percent(knob, -dt * hbt["dpleft"] * 0.6) end
    if input_type == "press" then _nudge_slider_by_percent(knob, -0.01) end
    return Y
end

--- Helper: slider_widget_right 
function Controller:_slider_widget_right(fct, input_type, dt, hbt)
    self.no_holdcap = Y
    local knob = fct.children[1];     _hover_child(knob, input_type == "press")
    if input_type == "hold" and hbt["dpright"] > 0.2 then _nudge_slider_by_percent(knob, dt * hbt["dpright"] * 0.6) end
    if input_type == "press" then _nudge_slider_by_percent(knob, 0.01) end
    return Y
end

--- Helper: slider_widget 
function Controller:_slider_widget(fct, b, input_type, dt)
    local hbt = self.held_button_times
    if b == "dpleft" then return self:_slider_widget_left(fct, input_type, dt, hbt)
    elseif b == "dpright" then return self:_slider_widget_right(fct, input_type, dt, hbt) end
end

--- Helper: option row slider
function Controller:_option_row_slider(fct, b, input_type, dt, args)
    local knob = _find_child_by_id(fct, args.knob_id);       if not knob then return N end
    self.no_holdcap = Y
    local hbt = self.held_button_times
    _hover_child(knob, input_type == "press")
    if b == "dpleft" and input_type == "press" then _nudge_slider_by_percent(knob, -0.01); return Y end
    if b == "dpright" and input_type == "press" then _nudge_slider_by_percent(knob, 0.01); return Y end
    if b == "dpleft" and input_type == "hold" and hbt.dpleft > 0.2 then _nudge_slider_by_percent(knob, -dt*hbt.dpleft*0.6); return Y end
    if b == "dpright" and input_type == "hold" and hbt.dpright > 0.2 then _nudge_slider_by_percent(knob, dt*hbt.dpright*0.6); return Y end
    return N
end

--- Helper: option row selector
function Controller:_option_row_selector(fct, b, input_type, args)
    if input_type ~= "press" then return N end
    if b == "dpleft"  then return _click_child(fct, args.prev_id) end
    if b == "dpright" then return _click_child(fct, args.next_id) end
    return N
end

--- Helper: option row switcher
function Controller:_option_row_switcher(fct, b, input_type, args)
    if input_type ~= "press" then return N end
    local on, off = _find_child_by_id(fct, args.on_id), _find_child_by_id(fct, args.off_id)
    _clear_hover_child(on); _clear_hover_child(off)
    if b == "dpleft"  then if on and on.click then on:click(); return Y end; return N end
    if b == "dpright" then if off and off.click then off:click(); return Y end; return N end
    if b ~= "a" then return N end
    local target = (on and on.config and on.config.selected) and off or on
    if target and target.click then target:click(); return Y end
    return N
end

--- Helper: option row button
function Controller:_option_row_button(fct, b, input_type, args)
    if input_type ~= "press" or b ~= "a" then return N end
    return _click_child(fct, args.button_id)
end

--- Helper: option row widget
function Controller:_option_row_widget(fct, b, input_type, dt)
    local args = fct.config.focus_args or {}
    if args.type == "slider_row"   then return self:_option_row_slider(fct, b, input_type, dt, args) end
    if args.type == "lr_row"       then return self:_option_row_selector(fct, b, input_type, args) end
    if args.type == "switch_row"   then return self:_option_row_switcher(fct, b, input_type, args) end
    if args.type == "button_row"   then return self:_option_row_button(fct, b, input_type, args) end
    return N
end

--- Helper: move focused card within its zone
function Controller:_shift_focused_card(fca, fct, step)
    local next_rank = fct.rank + step;              if next_rank < 1 or next_rank > #fca.cards then return N end

    fct.rank = next_rank
    fca.cards[next_rank].rank = next_rank - step
    table.sort(fca.cards, function(a, b) return a.rank < b.rank end)
    fca:align_cards()
    self:update_cursor()
    return Y
end

--- Helper: handle dpad press focus navigation
function Controller:_handle_dpad_focus_navigation(button, fca, fct, drt, hbt)
    if button ~= "dpleft" and button ~= "dpright" then return N end
    if not (fct and drt and (hbt["a"] and hbt["a"] < 0.12) and fca and fca:can_highlight(fct)) then return N end

    self:L_cursor_release()
    self:navigate_focus(button == "dpleft" and "L" or "R")
    hbt["a"], self.coyote_fcs = nil, Y
    return Y
end

--- Helper: handle dragged card reorder
function Controller:_handle_dragged_card_reorder(button, fca, fct, fcst)
    if not (fca and fct == self.dragging.target) then return N end
    fcst.drag.is = N

    if     button == "dpleft"  then self:_shift_focused_card(fca, fct, -1)
    elseif button == "dpright" then self:_shift_focused_card(fca, fct, 1)  end

    fcst.drag.is = Y
    return Y
end

--____________________________________________________________
-- Main: capture focused input
--____________________________________________________________
function Controller:capture_focused_input(button, input_type, dt)
    local ret, extern_button = N, N
    local fc,  drt,  fct     = self.focused,    self.dragging.target, nil
    self.no_holdcap, fct     = nil,              fc.target
    local fca, fcst, hbt     = fct and fct.zone, fct and fct.states,  self.held_button_times

    if input_type == "press" then
        if self:_handle_dpad_focus_navigation(button, fca, fct, drt, hbt) then ret = Y
        elseif self:_handle_dragged_card_reorder(button, fca, fct, fcst)  then ret = Y end
    end

    if self:_cancel_modal_confirm(button, input_type) then return Y end
    if self:_focus_modal_confirm_choice(button, input_type) then return Y end

    extern_button = self:_handle_shoulder_btns(fc, input_type, button)
    if fct and fct.config.focus_args then
        local args = fct.config.focus_args
        if args.type == "cycle" and input_type == "press" then ret = self:_cycle_widget(extern_button, button, fct) end
        if args.type == "tab"   and input_type == "press" then ret = self:_tab_widget(fct, extern_button, button)   end
        if args.type == "slider"                          then ret = self:_slider_widget(fct, button, input_type, dt) end
        if args.type and args.type:match("_row$")          then ret = self:_option_row_widget(fct, button, input_type, dt) end
    end

    if ret == Y then self:emit_intent("vibrate") end
    return ret
end

--------------------------------------------
--- Navigate focus
--------------------------------------------
function Controller:navigate_focus(dir)
    self:update_focus(dir)
    self:update_cursor()
end

--------------------------------------------
--- Save CardZone focus: saves the focus context to be loaded in the future
--------------------------------------------
function Controller:save_cardarea_focus(gm, _cardarea)
    if not gm[_cardarea] then return end
    local ft = self.focused.target;                         if not ft then return end

    local zone, context = ft.zone, self.cardarea_context
    local ma = ft.zone and (zone == gm[_cardarea])

    if ma then context[_cardarea] = self.focused.target.rank; return Y
    else context[_cardarea] = nil end
end

end
