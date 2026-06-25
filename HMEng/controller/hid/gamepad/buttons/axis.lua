local abs, sqrt = math.abs, math.sqrt

local DEADZONE = 0.1

return function(Controller)
-------------------------------------------------------------
--- Update axis
-------------------------------------------------------------
--- Helper: set the button presses/releases for the values determined in update_axis()
function Controller:_handle_axis_buttons()
    for _, v in pairs(self.axis_buttons) do
        local _p, _c = v.previous, v.current
        if _p ~= "" and (_c == "" or _p ~= _c) then self:button_release(v.previous) end
        if _c ~= "" and _p ~= _c then self:button_press(v.current) end
    end
end

-------------------------------------------------------------
--- Thumbstick helpers
-------------------------------------------------------------
function Controller:_handle_left_thumbstick(dt, gpobj, speed, cpos, CT, CVT, norm)
    local l_stick_x, l_stick_y = gpobj:getGamepadAxis("leftx"), gpobj:getGamepadAxis("lefty")
    if self.dragging.target and abs(l_stick_x) + abs(l_stick_y) > DEADZONE then
        if abs(l_stick_x) < DEADZONE then l_stick_x = 0 end
        if abs(l_stick_y) < DEADZONE then l_stick_y = 0 end
        l_stick_x = l_stick_x + (l_stick_x > 0 and -DEADZONE or 0) + (l_stick_x < 0 and DEADZONE or 0)
        l_stick_y = l_stick_y + (l_stick_y > 0 and -DEADZONE or 0) + (l_stick_y < 0 and DEADZONE or 0)

        CT.x,   CT.y    = CT.x + dt*l_stick_x*speed, CT.y + dt*l_stick_y*speed
        CVT.x,  CVT.y   = CT.x, CT.y
        cpos.x, cpos.y  = CT.x*norm, CT.y*norm
        return "axis_cursor"
    end

    local l = self.axis_buttons.l_stick
    l.current = l.previous
    if abs(l_stick_x) + abs(l_stick_y) > 0.5 then
        local ingame = self:_ingame_snap_active()
        return "button", abs(l_stick_x) > abs(l_stick_y) and (l_stick_x > 0 and (ingame and "camright" or "dpright") or (ingame and "camleft" or "dpleft")) or (l_stick_y > 0 and (ingame and "camdown" or "dpdown") or (ingame and "camup" or "dpup"))
    elseif abs(l_stick_x) + abs(l_stick_y) < 0.3 then l.current = "" end
end

--- Helper: _handle_right_thumbstick
function Controller:_handle_right_thumbstick(dt, gpobj, speed, cpos, CT, CVT, norm)
    local r_stick_x, r_stick_y = gpobj:getGamepadAxis("rightx"), gpobj:getGamepadAxis("righty")
    if sqrt(r_stick_x^2 + r_stick_y^2) <= DEADZONE then return end

    if abs(r_stick_x) < DEADZONE then r_stick_x = 0 end
    if abs(r_stick_y) < DEADZONE then r_stick_y = 0 end
    r_stick_x = r_stick_x + (r_stick_x > 0 and -DEADZONE or 0) + (r_stick_x < 0 and DEADZONE or 0)
    r_stick_y = r_stick_y + (r_stick_y > 0 and -DEADZONE or 0) + (r_stick_y < 0 and DEADZONE or 0)

    CT.x,   CT.y    = CT.x + dt*r_stick_x*speed, CT.y + dt*r_stick_y*speed
    CVT.x,  CVT.y   = CT.x, CT.y
    cpos.x, cpos.y  = CT.x*norm, CT.y*norm
    return "axis_cursor"
end

--_____________________________________________________________________________
-- Main: update_axis, handles all axis input for left stick, right stick and triggers. Treats them as buttons or cursors.
--_____________________________________________________________________________
function Controller:update_axis(dt)
    local axis_interpretation, abtn = nil, self.axis_buttons
    for _, b in pairs(abtn) do b.previous, b.current = b.current, "" end

    local function handle_rest() if axis_interpretation then self.interrupt.focus = N end; return axis_interpretation; end

    local HID,   gp     = self.HID, self.GAMEPAD;             if not HID.controller or not gp.object then return handle_rest() end
    local C             = self.p_cursor
    local gpobj, speed  = gp.object,            self.axis_cursor_speed
    local cpos,  rcfg   = self.cursor_position, self.rcfg
    local CT,    CVT    = C.T,                  C.VT
    local norm          = rcfg.tile_size*rcfg.tile_scale

    -- Left Thumbstick
    local l_kind, l_button = self:_handle_left_thumbstick(dt, gpobj, speed, cpos, CT, CVT, norm)
    if l_kind   then axis_interpretation = l_kind end
    if l_button then axis_interpretation = axis_interpretation or "button"; local l = self.axis_buttons.l_stick; l.current = l_button; end

    -- Right Thumbstick
    local r_kind = self:_handle_right_thumbstick(dt, gpobj, speed, cpos, CT, CVT, norm)
    if r_kind then axis_interpretation = r_kind end

    -- Triggers
    local l_trig, r_trig      = gpobj:getGamepadAxis("triggerleft"), gpobj:getGamepadAxis("triggerright")
    local lt,     rt          = abtn.l_trig, abtn.r_trig
    lt.current,   rt.current  = lt.previous, rt.previous

    if     l_trig > 0.5 then lt.current = "triggerleft"
    elseif l_trig < 0.3 then lt.current = "" end
    if     r_trig > 0.5 then rt.current = "triggerright"
    elseif r_trig < 0.3 then rt.current = "" end

    if rt.current ~= "" or lt.current ~= "" then axis_interpretation = axis_interpretation or "button" end
    self:_handle_axis_buttons()
    return handle_rest()
end

end
