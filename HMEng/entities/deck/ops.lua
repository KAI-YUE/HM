local TabUtils  = require("HMfns.utils.table_utils")
local I18N = require("HMfns.utils.format.i18n_utils")

local i18n      = I18N.i18n
local deep_copy = TabUtils.deep_copy

local savable = { "name", "pos", "effect", "loc_name" }

return function (Deck)
-----------------------------------------
--- Change to: switch to a new back 
-----------------------------------------
function Deck:change_to(back)
    if not back then back = self.default_back end

    self.name     = back.name or "Red Deck"
    self.effect   = { center = back, config = deep_copy(back.config) }
    self.loc_name = self.Ld[back.key].name

    local unlocked,  pos = back.unlocked, { x = 4, y = 0 }
    if unlocked then pos = back.pos end

    local sp = self.pos
    sp.x, sp.y = pos.x, pos.y
end

----------------------------------------------------
--- Save 
----------------------------------------------------
function Deck:save() local t = {}; for _, v in ipairs(savable) do t[v] = self[v] end; return t end

----------------------------------------------------
--- load
----------------------------------------------------
function Deck:load(gm, backup) 
    for _, v in ipairs(savable) do self[v] = backup[v] end 
    self.effect.template = gm.CMod[backup.key] or gm.CMod.b_red
end

end