local TabUtils  = require("HMfns.utils.table_utils")
local Render, C = require("HMfns.systems.render"), require("HMfns.animate.color.color_const")

local push_draw_trans  = Render.push_actor_draw_transform
local enqueue_drawable = Render.enqueue_drawable
local push, wipe, cw   = table.insert, TabUtils.wipe, C.WHITE
local abs, LG          = math.abs, love.graphics
local Y, N             = true, false

return function (ParticleEmitter)
---------------------------------------------------
--- Draw 
---------------------------------------------------
function ParticleEmitter:draw(alpha)
    alpha = alpha or 1;       push_draw_trans(self)
    LG.translate(self.T.w/2, self.T.h/2)

    for k, v in pairs(self.particles) do
        if not v.draw then goto continue end
        LG.push()
        local vc, vo, vs = v.color, v.offset, v.scale
        LG.setColor(vc[1], vc[2], vc[3], vc[4]*alpha*(1-self.draw_alpha))                
        LG.translate(vo.x, vo.y)
        LG.rotate(v.facing)
        
        LG.rectangle("fill", -vs/2, -vs/2, vs, vs) -- origin in the middle
        LG.pop()
        ::continue::
    end
    LG.setColor(cw)
    LG.pop()
    enqueue_drawable(self.t_drawable, self)
    self:bound_me()
end

----------------------------------------------------
--- Fade
----------------------------------------------------
function ParticleEmitter:fade(delay, to)
    local te, tt, rv, et = "ease", self.timer_type, "draw_alpha", to or 1
    self.EM:enqueue_event({ trigger = te, timer = tt, blockable = N, blocking = N, ref_value = rv, ref_table = self, ease_to = et, delay = delay })
end

end
