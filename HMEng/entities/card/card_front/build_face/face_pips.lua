local LG = love.graphics

local min  = math.min
local rand = math.random

local PI   = math.pi
local Y    = true

return function (CardFront)
------------------------------------------
--- render_custom_face
--------------------------------------------------
function CardFront:_render_custom_face(cw, ch)
    local img, q = self.face_img, self.face_quad;        if not img or not q then return end

    local _scale = 0.8
    local _,   _,   vw,   vh  = q:getViewport()
    local target_w, target_h  = _scale*cw, _scale*ch

    local s, r  = min(target_w/vw, target_h/vh), 0.03*(rand() - 0.5)
    local x, y  = 0.48*cw,                       0.44*ch

    LG.draw(img, q, x, y, r, s, s, 0.5*vw, 0.5*vh)
end

---------------------------------------------------
--- render_pip_face 
---------------------------------------------------
--- Helper: apply_base_rot 
local function _apply_base_rot(pips, i, r)
    r = r + 0.25*(rand() - 0.5)
    pips[i][3], pips[i][6] = r, Y
    return pips[i][1], pips[i][2], r
end

--- Helper: apply_random_flip
local function _apply_random_flip(pips, i, nx, ny, r)
    local flip, r_offset = (rand() < 0.5), 0
    if flip then r_offset = r_offset + PI end

    r      = r + 0.14*(rand() - 0.5) + r_offset
    nx, ny = nx + 0.05*rand()*nx, ny + 0.05*rand()*ny
    pips[i][3], pips[i][6] = r, flip
    return nx, ny, r
end

--- Helper: apply_prev_rot
local function _apply_prev_rot(pips, i)
    local r = pips[i-1][3] + 0.14*(rand() - 0.5)
    pips[i][3], pips[i][6] = r, Y
    return pips[i][1], pips[i][2], r
end

--- Helper: resolve_pip_pose 
local function _resolve_pip_pose(pips, i, nx, ny, r, r_mod)
    if     r_mod == nil then return _apply_base_rot(pips, i, r)
    elseif r_mod == -1  then return _apply_random_flip(pips, i, nx, ny, r)
    elseif r_mod == -2  then return _apply_prev_rot(pips, i) end
    return nx, ny, r
end

---_____________________________________________________
--- main: render_pip_face
---_____________________________________________________
function CardFront:_render_pip_face(cw, ch)
    local pips, target = self.pips, 0.55*cw

    for i = 1, #pips do
        local nx, ny, r, ns, res, r_mod = pips[i][1], pips[i][2], pips[i][3], pips[i][4], pips[i][5], pips[i][6]
        nx, ny, r = _resolve_pip_pose(pips, i, nx, ny, r, r_mod)

        local img,  q       = self.fine_s_imgs[res], self.fine_quads[res]
        local _, _, vw, vh  = q:getViewport()
        local s = target/vw*(1 + 0.1*rand())

        LG.draw(img, q, nx*cw, ny*ch, r, ns*s, ns*s, 0.5*vw, 0.5*vh)
    end
end

end
