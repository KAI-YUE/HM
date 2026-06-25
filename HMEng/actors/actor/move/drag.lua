local GameObj   = require("HMEng.actors.game_obj")
local MathUtils = require("HMfns.utils.math.math_utils")

local t_in, r_in = MathUtils.vec_translate_inplace, MathUtils.vec_rotate_inplace

return function(Actor)
----------------------------------------------------
--- Drag
---------------------------------------------------
function Actor:drag(Ctrl, offset)
    local drc =  self.states.drag.can;            if not drc and not offset then return end
    
    local rcfg,  cT       = self.rcfg,            self.container.T
    local cpos,  args     = Ctrl.cursor_position, self.args
    local tsize, tscale   = rcfg.tile_size,       rcfg.tile_scale
    local norm,  T        = tsize * tscale,       self.T

    local _p, _t    = args.drag_cursor_trans or {}, args.drag_translation or {}
    _p.x,     _p.y  = cpos.x / norm,                cpos.y / norm   
    _t.x,     _t.y  = -cT.w/2,                      -cT.h/2
    
    t_in(_p, _t)            
    r_in(_p, cT.r)
    
    _t.x, _t.y  = cT.w/2 - cT.x, cT.h/2 - cT.y     
    t_in(_p, _t)

    if not offset then offset = self.click_offset end
    T.x, T.y = _p.x - offset.x, _p.y - offset.y

    self.new_align = true
    if self.wake_move then self:wake_move() end
    for _, v in pairs(self.children) do v:drag(Ctrl, offset) end
    GameObj.drag(Ctrl, self)
end

end
