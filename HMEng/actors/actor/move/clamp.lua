return function(Actor)
----------------------------------------
--- LR clamp
--------------------------------------
function Actor:lr_clamp()
    local T, _room  = self.T, self._room
    local VT, RT    = self.VT, _room.T
    if T.x < 0 then T.x = 0 end; if VT.x < 0 then VT.x = 0 end
    if (T.x + T.w) > RT.w then T.x = RT.w - RT.w end; if (VT.x + VT.w) > RT.w then VT.x = RT.w - VT.w end
end

end
