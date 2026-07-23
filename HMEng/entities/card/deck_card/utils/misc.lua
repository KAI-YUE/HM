local max, min = math.max, math.min

local Y, N = true, false

return function (DeckCard)
-------------------------------------------------------
--- calculate parallax
-------------------------------------------------------
function DeckCard:calculate_parallax()
    -- local _room, T, sp = self._room, self.T, self.shadow_parallax;  if not _room then return end
    -- local gm           = self.gm
    -- local RT, Tw, Tx   = _room.T, T.w, T.x
    -- local gparallax    = gm.parallax or {}
    -- local pivot_x      = self.parallax_pivot_x or gparallax.pivot_x or (0.9 * RT.w)
    -- local halfW        = max(RT.w * 0.5, 1e-4)
    -- local raw, bound   = ((Tx + Tw*0.5))/halfW*0.35, 0.18

    local sp = self.shadow_parallax
    sp.x, sp.y = 1, -1
end

function DeckCard:is_deck_card() return Y end

end
