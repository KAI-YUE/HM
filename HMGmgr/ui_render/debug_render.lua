local LG = love.graphics
local Y  = true

-----------------------------
--- helpers
----------------------------
local function _ctrl(self) return self.CTRL or (G and G.CTRL) end
local function _field_focus_cell(ctrl)
    local cell = ctrl and ctrl.field_focus_cell
    if cell and cell.row and cell.col then return cell end
    local fct = ctrl and ctrl.focused and ctrl.focused.target
    if fct and fct.cell and fct.zone and fct.zone.config and fct.zone.config.type == "field" then return fct.cell end
end

return function (GMgr)
-----------------------------
--- simulated controller
----------------------------
--- Helper: simulated controller badge
function GMgr:debug_simulated_controller()
    local ctrl = _ctrl(self);                  if _RELEASE_MODE or not (ctrl and ctrl.debug_gamepad_mode) then return end
    local probe = ctrl.debug_gamepad_probe or {}
    local msg = "simulated controller"
    if probe.button then msg = msg .. " | " .. tostring(probe.key or "?") .. " -> " .. tostring(probe.button) .. " | " .. tostring(probe.snap or "") end
    local cell = _field_focus_cell(ctrl)
    if cell and cell.row and cell.col then msg = msg .. "\nfield snap: (" .. tostring(cell.row) .. ", " .. tostring(cell.col) .. ")" end
    LG.push(); LG.setColor(1, 0.82, 0.22, 1); LG.print(msg, 10, 10, 0, 1.55, 1.55); LG.pop()
    return Y
end

-----------------------------
--- fps
----------------------------
--- Helper: debug fps
function GMgr:debug_fps()
    if _RELEASE_MODE or not self.debug.on or not self.F.verbose then return end

    LG.push();                          LG.setColor(0, 1, 1,1)
    local ctrl = _ctrl(self)
    local y0 = (ctrl and ctrl.debug_gamepad_mode) and 52 or 10
    local fps = love.timer.getFPS();    LG.print("Current FPS: "..fps, 10, y0)
    local vsync = love.window.getVSync and love.window.getVSync() or (self.SET and self.SET.s_win and self.SET.s_win.vsync)
    LG.print("V_sync: "..((vsync ~= 0) and "ON" or "OFF"), 10, y0 + 15)

    local _c, SET = self.check, self.SET
    if not _c or not SET.perf_mode then return LG.pop() end
    local section_h, resolution = 30, 60*section_h
    local poll_w, v_off = 1, 100

    for a, b in ipairs({ _c.update, _c.draw }) do
        for k, v in ipairs(b.checkpoint_list) do
            LG.setColor(0,0,0,0.2)
            LG.rectangle("fill", 12, 20 + v_off, poll_w + poll_w*#v.trend, -section_h + 5)
            for kk, vv in ipairs(v.trend) do
                if a == 2 then LG.setColor(0.3,0.7,0.7,1)
                else  LG.setColor(self:state_col(v.states[kk] or 123)) end
                LG.rectangle("fill", 10 + poll_w*kk,  20 + v_off, 5*poll_w, -(vv)*resolution)
            end
            LG.setColor(a == 2 and 0.5 or 1, a == 2 and 1 or 0.5, 1,1)
            LG.print(v.label..": "..(string.format("%.2f", 1000*(v.average or 0))).."\n", 10, -section_h + 30 + v_off)
            v_off = v_off + section_h
        end
    end
    LG.pop()
end

end
