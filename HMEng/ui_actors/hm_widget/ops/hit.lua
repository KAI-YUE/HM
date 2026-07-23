local GameObj   = require("HMEng.actors.game_obj")
local renderers = require("HMEng.ui_actors.hm_widget.renderers")

local Y, N = true, false

return function(HMWidget)

-----------------------------
--- Hit test
----------------------------------
--- Helper: _hit_box
local function _hit_box(point, T)
    local x, y, w, h  = T.x, T.y, T.w, T.h
    local px,   py    = point.x, point.y
    return px >= x and py >= y and px <= x + w and py <= y + h
end

--- Helper: _hit_area
local function _hit_area(self, cursor_trans)
    local cfg = self.config
    if cfg.hit_area == "world" then return Y end
    if cfg.hit_area == "room" then return _hit_box(cursor_trans, self.gm._room.T) end
end

---____________________________
--- main: hit_test
---______________________________________
function HMWidget:hit_test(cursor_trans)
    if not self.states.collide.can then return N end

    local area_hit = _hit_area(self, cursor_trans);         if area_hit ~= nil then return area_hit end
    local cfg      = self.config

    local renderer = renderers[cfg.renderer]
    if renderer and renderer.hit_test_outer and (cfg.hit_shape == nil or cfg.hit_shape == "rect") then return renderer.hit_test_outer(self, cursor_trans) end

    if not GameObj.hit_test(self, cursor_trans) then return N end
    if renderer and renderer.hit_test then return renderer.hit_test(self, self.args.collides_with_point_point or cursor_trans) end
    return Y
end

end
