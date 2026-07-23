local QuickLoad  = require("HMGmgr.interactions.debug.quick_load")
local Profile    = require("HMGmgr.interactions.debug.profile")
local Language   = require("HMGmgr.interactions.debug.language")
local Tools      = require("HMGmgr.interactions.debug.tools")
local Controller = require("HMGmgr.interactions.debug.controller")

return function(GMgr)
    QuickLoad.install(GMgr)
    Profile.install(GMgr)
    Language.install(GMgr)
    Tools.install(GMgr)
    Controller.install(GMgr)
end

