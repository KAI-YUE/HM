local C, CL = require("HMfns.animate.color.color_const"), require("HMEng.entities.card.card_front.build_face.basic_layout")

local CLC    = CL.corner
local CR, CS = CLC.top_rank, CLC.top_suit
local LG     = love.graphics
local rand   = math.random
local PI     = math.pi

return function (CardFront)
--------------------------------------------------
--- Renderers: corner identity
--------------------------------------------------
function CardFront:_render_rank(cw, ch)
    local q = self.Qrank
    local _, _, vw, vh = q:getViewport()

    local target, r = CR.s*cw, 0.4*(rand() - 0.5)
    local rx, ry, s = CR.x, CR.y, target/vw
    LG.setColor(self.rank_color or C.WHITE)
    LG.draw(self.r_img, q, rx*cw, ry*ch, r, s, s, 0.5*vw, 0.5*vh)

    local brx, bry  = 1 - rx, 1 - ry
    LG.draw(self.r_img, q, brx*cw, bry*ch, r + PI, s, s, 0.5*vw, 0.5*vh)
    LG.setColor(1, 1, 1, 1)
end

function CardFront:_render_cor_suit(cw, ch)
    local q = self.Qsuit
    local _, _, vw, vh = q:getViewport()

    local target, r = CS.s*cw, 0.2*(rand() - 0.5)
    local sx, sy, s = CS.x, CS.y, target/vw
    LG.draw(self.s_img, q, CS.x*cw, CS.y*ch, r, s, s, 0.5*vw, 0.5*vh )

    local bsx, bsy  = 1 - sx, 1 - sy
    LG.draw(self.s_img, q, bsx*cw, bsy*ch, r + PI, s, s, 0.5*vw, 0.5*vh )
end

end
