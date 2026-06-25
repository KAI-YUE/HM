local FileIO  = require("core.io.fileio")
local UI, URL = require("HMui"), require("core.url.init")
local Gplay   = require("HMGplay")

return function (GMgr)
-----------------------------
--- init gm attributes
----------------------------------
function GMgr:init_gm_attributes()
    G = self
    self:set_globals()
    
    local fmods, M = FileIO.list_folders("HMfns"), nil       -- Register the modules under functions
    for _, m in ipairs(fmods) do M = require(("HMfns.%s"):format(m)); M.register(self) end
    
    UI.register(self)
    URL.register(self)
    Gplay.register(self)

    self.C = require("HMfns.animate.color.color_const")
    self.debugger = require("core.HMdebug")
end

end