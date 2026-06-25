local TabUtils  = require("HMfns.utils.table_utils")
local I18N = require("HMfns.utils.format.i18n_utils")

local deep_copy = TabUtils.deep_copy
local i18n = I18N.i18n

return function (Deck)
-------------------------------------
--- init_back_attributes
-------------------------------------
function Deck:init_back_attributes(gm, back)
    self.default_back = gm.CMod.b_red
    if not back then back = self.default_back end
    
    self.name, self.locked_name = back.name or "Red Deck", i18n(gm, "k_locked")
    self.effect   = { center = back, config = deep_copy(back.config) }
    self.loc_name = self.name

    local unlocked,  pos = back.unlocked, { x = 4, y = 0 }
    if unlocked then pos = back.pos end 
    self.pos, self.gm    = pos, gm
end

end