local Context   = require("HMEng.controller.hid.mouse.cursor.context")
local Collision = require("HMEng.controller.hid.mouse.cursor.collision")
local Hover     = require("HMEng.controller.hid.mouse.cursor.hover")
local Press     = require("HMEng.controller.hid.mouse.cursor.press")

return function(Controller)
    Context.install(Controller)
    Collision.install(Controller)
    Hover.install(Controller)
    Press.install(Controller)
end
