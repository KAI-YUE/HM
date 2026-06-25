local Actor    = require("HMEng.actors.actor")
local Spritor  = require("HMEng.actors.spritor")

local Tst   = { "hover", "click", "drag" }
local Y, N  = true, false

return function (Pawn)
------------------------------------------------------
--- hard set T
-----------------------------------------------------
function Pawn:hard_set_T(x, y, w, h)
    local T, ch = self.T, self.children
    x, y, w, h = x or T.x, y or T.y, w or T.w, h or T.h
    Actor.hard_set_T(self, x, y, w, h)

    local visual, shadow = ch.visual, ch.shadow
    if visual then visual:hard_set_T(x, y, w, h) end
    if shadow then shadow:hard_set_T(x, y, w, h) end
end

------------------------------------------------------
--- assign visual
-----------------------------------------------------
function Pawn:assign_visual(sprite_name, atlas_key)
    local gm, ch, T = self.gm, self.children, self.T
    if not sprite_name then return end

    self.params.sprite_name, self.params.atlas_key = sprite_name, atlas_key
    local TA = gm.T_atlas or {}
    local atlas = (atlas_key and TA[atlas_key]) or TA.pawns
    if not atlas then return end

    local x, y, w, h = T.x, T.y, T.w, T.h
    ch.visual = Spritor(gm, x, y, w, h, atlas, sprite_name)
    
    local visual, st = ch.visual, self.states
    local vst = visual.states
    
    for _, k in ipairs(Tst) do vst[k] = st[k] end
    vst.collide.can = N
    visual:set_role({ major = self, role_type = "Glued", draw_major = self })
end

end
