local Actor = require("HMEng.actors.actor")

local min, max = math.min, math.max

-- Helper: clamp
local function clamp(v, lo, hi) if lo > hi then return 0.5*(lo + hi) end; return max(lo, min(hi, v)) end

return function (Card)
---------------------------------------
--- Calculate Parallax
---------------------------------------
function Card:calculate_parallax()
    -- Actor.calculate_parallax(self)

    local st, sp, zone = self.states, self.shadow_parallax, self.zone; -- if zone and zone.is_hand and zone:is_hand() then print(sp.x) end
    sp.x = .5; 
    if not (st.dealing and st.dealing.is) then sp.y = -1; return end

    sp.y = -0.8
    if self.sprite_facing ~= "back" then return end
    
    sp.x = clamp(sp.x*1.8, 2, 2)
    if self.pinch.x then sp.x = 0.3*sp.x end 
end

end
