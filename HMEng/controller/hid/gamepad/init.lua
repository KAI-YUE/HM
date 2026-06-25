local p_list, c_list = { "mouse", "axis_cursor", "touch" }, { "button", "axis_cursor" }
local ps, nin        = { "%f[%w]PS%d%f[%D]", "Sony%f[%W]", "Play[Ss]tation" }, { "Wii%f[%L]", "%f[%u]S?NES%f[%U]", "%f[%l]s?nes%f[%L]", "%f[%u]Switch%f[%L]", "Joy[- ]Cons?%f[%L]" }

return function(Controller)
-------------------------------------------------
--- Set Gamepad
-------------------------------------------------
function Controller:set_gamepad(_gamepad)
    local gp, c = self.GAMEPAD, self.GAMEPAD_CONSOLE;                   if gp.object == _gamepad then return end
    if not _gamepad then self.GAMEPAD_CONSOLE, gp.object, gp.mapping, gp.name = "", nil, nil, nil; return end

    local mapping = (_gamepad.getGamepadMappingString and _gamepad:getGamepadMappingString()) or ""
    local name    = mapping:match("^%x*,(.-),") or (_gamepad.getName and _gamepad:getName()) or ""
    local console = self:get_console_from_gamepad(name)

    gp.object, gp.mapping       = _gamepad, mapping
    gp.name,   gp.temp_console  = name, console

    if c == gp.temp_console then return end
    self.GAMEPAD_CONSOLE = gp.temp_console
end

-------------------------------------------------
--- Get console from Gamepad
-------------------------------------------------
function Controller:get_console_from_gamepad(_gamepad)
    local args = self.args
    _gamepad = tostring(_gamepad or "")
    args.gamepad_patterns = args.gamepad_patterns or { Playstation = ps, Nintendo = nin }
    for k, patterns in pairs(args.gamepad_patterns) do for _, pat in ipairs(patterns) do if _gamepad:match(pat) then return k end end end
    return "Xbox"
end

---------------------------------
--- Set HID flags: The controller for the type of HID
---------------------------------
function Controller:set_HID_flags(HID_type)
    local HID, gp, contains  = self.HID,   self.GAMEPAD,  self.Fs.contains
    local _p,  _c            = contains(p_list, HID_type), contains(c_list, HID_type)

    if HID_type == "axis" then HID.controller, HID.last_type = true, "axis"
    elseif HID_type and HID_type ~= HID.last_type then
        HID.dpad,  HID.pointer     = (HID_type == "button"), _p
        HID.mouse, HID.controller  = (HID_type == "mouse"), _c
        HID.touch, HID.last_type   = (HID_type == "touch"), HID_type
        HID.axis_cursor            = (HID_type == "axis_cursor")
        love.mouse.setVisible(self.HID.mouse)
    end
    if HID.controller then return end
    self.GAMEPAD_CONSOLE, gp.object, gp.mapping, gp.name = "", nil, nil, nil
end

-------------------------------------------------
--- Gamepad Install
-------------------------------------------------
local install_list = { "buttons.init", "focus.init" }
for _, pkg in ipairs(install_list) do require("HMEng.controller.hid.gamepad." .. pkg)(Controller) end

end
