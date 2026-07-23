local Scope   = require("HMEng.controller.hid.gamepad.focus.scope")
local Targets = require("HMEng.controller.hid.gamepad.focus.targets")
local Collect = require("HMEng.controller.hid.gamepad.focus.collect")
local Resolve = require("HMEng.controller.hid.gamepad.focus.resolve")

local Y, N = true, false

return function(Controller)
Scope.install(Controller)

-----------------------------
--- Focus effects
----------------------------
--- Helper: clear child hover
local function _clear_child_hover(node)
    local st = node and node.states
    local hst = st and st.hover
    if hst then if hst.is and node.stop_hover then node:stop_hover() else hst.is = N end end
    local fst = st and st.focus;                                      if fst then fst.is = N end
    for _, child in ipairs((node and node.children) or {}) do _clear_child_hover(child) end
    for _, child in ipairs((node and node.page_child_widgets) or {}) do _clear_child_hover(child) end
    for _, child in ipairs((node and node.page_card_textfx) or {}) do _clear_child_hover(child) end
end

--- Helper: apply row focus fx
local function _apply_row_focus_fx(node)
    local args = node and node.config and node.config.focus_args;    if not (args and args.type == "slider_row") then return end
    local knob = Targets.find_node_by_id(node, args.knob_id);        if not knob then return end
    local st = knob.states;                                          if st and st.focus then st.focus.can, st.focus.is = Y, Y end
    knob.last_hovered = nil
    if knob.hover then knob:hover() end
end

---------------------------------------------------------
--- Update Focus
---------------------------------------------------------
--- Helper: auto snap focus
function Controller:auto_snap_focus()
    if not Scope.on_title_page(self) then self.debug_gamepad_probe = { snap = "no title" }; return N end
    local node = Targets.auto_snap_focus_target(self);             if not node then self.debug_gamepad_probe = { snap = "no target" }; return N end
    self.interrupt.focus = N
    self:snap_to({ node = node })
    self.debug_gamepad_probe = { button = (self.debug_gamepad_probe and self.debug_gamepad_probe.button), key = (self.debug_gamepad_probe and self.debug_gamepad_probe.key), snap = "queued" }
    return Y
end

--- Helper: decide if the target is focusable
function Controller:_prepare_focus_target(fc, CT, HID)
    local fct = fc.target;          fct.states.focus.is = N
    Scope.wake_zone_layout(fct)
    if not self:focus_scope_allows_node(fct) then fc.target = nil; return end
    if self:is_focusable(fct) and (not HID.axis_cursor or fct:hit_test(CT)) then return end
    fc.target = nil
end

--- Helper: push focusable candidates into args.focusables
function Controller:_build_focusable_candidates(dir, fct, args) return Collect.build_focusable_candidates(self, dir, fct, args, Scope, Targets) end

-- Helper: add a node to the focus_list
function Controller:_push2fcslist() return Resolve.push_current(self) end

--- Helper: choose the final target
function Controller:_final_target(dir) return Resolve.final_target(self, dir, Scope, Targets) end

--____________________________________________________________
-- Main: apply all updates to the controller
--____________________________________________________________
function Controller:update_focus(dir)
    local HID, args, C = self.HID, self.args, self.p_cursor
    local CT, fc, wipe = C.T, self.focused, self.Fs.wipe
    fc.prev_target = fc.target

    if not HID.controller or self.interrupt.focus or self:_locked() then
        if fc.target then _clear_child_hover(fc.target); fc.target.states.focus.is = N end
        fc.target = nil
        return
    end

    args.focus_list, args.focusables = wipe(args.focus_list), wipe(args.focusables)
    if fc.target then self:_prepare_focus_target(fc, CT, HID) end
    self:_build_focusable_candidates(dir)

    local ingame_hand_default = (not dir and not fc.target) and Scope.first_ingame_hand_focus(self)
    if ingame_hand_default or #args.focusables > 0 or (dir and not fc.target) then if self:_final_target(dir) then return end end
    local flist = args.focus_list[1]
    if flist then
        local node = flist.node
        local nfargs = node.config.focus_args
        local next_target = nfargs and nfargs.funnel_from or node
        if self:focus_scope_allows_node(next_target) then fc.target = next_target else _clear_child_hover(fc.prev_target); fc.target = nil end
        if fc.target and fc.target ~= fc.prev_target then _clear_child_hover(fc.prev_target); Scope.wake_zone_layout(fc.prev_target); Scope.wake_zone_layout(fc.target); _apply_row_focus_fx(fc.target); self:emit_intent("vibrate") end
    else _clear_child_hover(fc.prev_target); fc.target = nil end
    if fc.target then fc.target.states.focus.is = Y; Scope.apply_hand_card_focus_hover(self, fc.target) end
end

end
