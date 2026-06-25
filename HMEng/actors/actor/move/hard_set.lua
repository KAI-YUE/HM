local coord = { "x", "y", "w", "h" }
local _ovel = { "x", "y", "r", "scale" }

return function (Actor)
-- Helper: set the transform tables
local function _set_T(T, cfg) for _, v in ipairs(coord) do T[v] = cfg[v] end end

---_________________________________
-- Main: hard set T
---_________________________________
function Actor:hard_set_T(x, y, w, h)
    local cfg, T, VT = { x = x, y = y, w = w, h = h }, self.T, self.VT
    VT.r, VT.scale = T.r, T.scale

    for _, t in ipairs({ T, VT }) do _set_T(t, cfg) end
    for _, k in ipairs(_ovel) do self.velocity[k] = 0 end
    self:calculate_parallax()
    if self.wake_move then self:wake_move() end
end

-- Main: hard set VT
function Actor:hard_set_VT() _set_T(self.VT, self.T); if self.wake_move then self:wake_move() end end

end
