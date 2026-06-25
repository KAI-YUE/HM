local min, max = math.min, math.max

local Parallax = {}

--------------------------------------------
--- shadow x
--------------------------------------------
function Parallax.shadow_x(gm, room_T, T)
    if not room_T or not T then return 0 end

    local gparallax      = gm and gm.parallax or {}
    local pivot_x, halfW = gparallax.pivot_x or 0.9, room_T.w/2
    if halfW == 0 then return 0 end

    local raw, bound = (pivot_x - ((T.x or 0) + (T.w or 0)*0.5))/halfW, 0.07*pivot_x
    return max(-2*bound, min(bound, raw))
end

---------------------------------------------------
--- Calculate Parallax
---------------------------------------------------
function Parallax.__call(_, Actor)
    function Actor:calculate_parallax()
        local _room = self._room;       if not _room then return end

        local sp = self.shadow_parallax
        sp.x = Parallax.shadow_x(self.gm, _room.T, self.T)
    end
end

setmetatable(Parallax, { __call = Parallax.__call })

return Parallax
