local M = {}

-----------------------------
--- profile helpers
----------------------------------
function M.install(GMgr)
--- Helper: profile game
function GMgr:_profile_game()
    if not self.prof then self.prof = require "HMEng.my_io.profile"; self.prof.start(); return end
    self.prof:stop();                      local r = self.prof.report()
    self.debugger.save_table({r}, "p.hm"); self.prof = nil
end
end

return M

