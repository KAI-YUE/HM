local shared = require("HMEng.controller.update.shared")


local enqueue_after = shared.enqueue_after
local input_update_groups = shared.input_update_groups
local tU = shared.tU

local Y, N = true, false

return function(Controller)
-----------------------------------------------------------
--- Helper: update overlay timer
-----------------------------------------------------------
function Controller:_update_overlay_timer(dt)
    self.overlay_timer = self.overlay_timer or 0
    local OM = self.UI.overlay_menu
    if OM then self.overlay_timer = self.overlay_timer + dt
    else self.overlay_timer = 0 end
    if self.overlay_timer > 1.5 then self.locks.frame = nil end
end

-----------------------------------------------------------
--- Helper: handler locks frame
-----------------------------------------------------------
function Controller:_handle_locks_frame(gm)
    self.locks.frame_set, self.overlay_timer = nil, 0
    enqueue_after(gm.E_MANAGER, 0.1, function()
        self.locks.frame = nil
        return Y
    end, { timer = tU, blocking = N, no_delete = Y, settings = self.SET, _T = self._T })
end

-----------------------------------------------------------
--- Helper: handle button press and hold
-----------------------------------------------------------
function Controller:_handle_press_hold(dt)
    for _, group in ipairs(input_update_groups) do
        local fn = self[group.fn]
        for k, v in pairs(self[group.values]) do
            if v then fn(self, k, dt) end
        end
    end
end

-----------------------------------------------------------
--- Helper: refresh locks and _T
-----------------------------------------------------------
function Controller:_update_locks_and__T(gm, dt)
    local L = self.locks
    self.locked, L.wipe = N, self.screenwipe or N
    for _, v in pairs(L) do
        if v then self.locked = Y end
    end

    if L.frame_set then self:_handle_locks_frame(gm) end
    self:_update_overlay_timer(dt)
end

-----------------------------------------------------------
--- Helper: update HID and cursor position
-----------------------------------------------------------
function Controller:_update_cursor_state(dt)
    local HID, C = self.HID, self.p_cursor
    self:set_HID_flags(self:update_axis(dt))

    if HID.pointer and not (HID.mouse or HID.touch) and not self.interrupt.focus then C.states.visible = Y
    else C.states.visible = N end
    self:set_cursor_position()
end

-----------------------------------------------------------
--- Helper: process held/pressed input and clear one-frame input
-----------------------------------------------------------
function Controller:_update_button_inputs(dt)
    if not self.screenwipe then self:_handle_press_hold(dt) end
    self.frame_buttonpress = N

    local wipe = self.Fs.wipe
    self.pressed_keys, self.released_keys = wipe(self.pressed_keys), wipe(self.released_keys)
    self.pressed_buttons, self.released_buttons = wipe(self.pressed_buttons), wipe(self.released_buttons)
end

-----------------------------------------------------------
--- Helper: update collision/focus/hover candidates
-----------------------------------------------------------
function Controller:_update_cursor_targets()
    local HID, C = self.HID, self.p_cursor
    if HID.controller then self:_handle_controller() end
    self:get_cursor_collision(C.T)
    self:update_focus()
    self:set_cursor_hover()
end

-----------------------------------------------------------
--- Helper: snapshot current interaction targets
-----------------------------------------------------------
function Controller:_snapshot_interaction_targets()
    local Lq, dr, r, c, h = self.L_cursor_queue, self.dragging, self.released_on, self.clicked, self.hovering
    if Lq then self:L_cursor_press(Lq.x, Lq.y); self.L_cursor_queue = nil end
    dr.prev_target, r.prev_target = dr.target, r.target
    c.prev_target, h.prev_target = c.target, h.target
end

end
