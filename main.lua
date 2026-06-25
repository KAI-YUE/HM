if (love.system.getOS() == "OS X" ) and (jit.arch == "arm64" or jit.arch == "arm") then jit.off() end

local MRun   = require("love.run")
local MLoad  = require("love.load")
local MCtrl  = require("love.ctrl")
local MRes   = require("love.resize")

function love.run()       return MRun.run() end
function love.load()      MLoad.load()      end
function love.quit()      MRun.quit()       end
function love.draw()      G:draw()          end
function love.update(dt)  G:update(dt)      end

function love.keypressed(key)                      MCtrl.keypressed(key) end
function love.keyreleased(key)                     MCtrl.keyreleased(key) end
function love.mousepressed(x, y, button, touch)    MCtrl.mousepressed(x, y, button, touch) end 
function love.mousereleased(x, y, button)          MCtrl.mousereleased(x, y, button) end
function love.mousemoved(x, y, dx, dy, istouch)    MCtrl.mousemoved(x, y, dx, dy, istouch) end
function love.wheelmoved(x, y)                     MCtrl.wheelmoved(x, y) end
function love.joystickaxis(joystick, axis, value)  MCtrl.joystickaxis(joystick, axis, value) end
function love.gamepadpressed(joystick, button)     MCtrl.gamepadpressed(joystick, button) end
function love.gamepadreleased(joystick, button)    MCtrl.gamepadreleased(joystick, button) end
function love.resize(w, h)                         MRes.resize(w, h) end
