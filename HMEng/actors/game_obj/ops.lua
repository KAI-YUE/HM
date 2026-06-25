local MathUtils  = require("HMfns.utils.math.math_utils")
local LG         = love.graphics

local push, pop, abs  = table.insert, table.remove, math.abs
local sin,  cos, pi   = math.sin, math.cos, math.pi 
local r_in, t_in      = MathUtils.vec_rotate_inplace, MathUtils.vec_translate_inplace

local Tcelems        = { "collides_with_point_point", "collides_with_point_translation", "collides_with_point_rotation" }
local Toffsets       = { "set_offset_point", "set_offset_translation" } 

local Y, N = true, false


return function (GameObj)
------------------------------------------------------
-- Collide with point
-------------------------------------------------------
--- Helper: collide against (T) or not 
local function _collide(p, T, b, debug_on)
    local px, py, Tx, Ty, h, w = p.x, p.y, T.x, T.y, T.h, T.w; 
    local collided = (px >= Tx - b and py >= Ty - b and px <= Tx + w + b and py <= Ty + h + b)
    return collided 
end

--- Helper: translate to the container space
function GameObj:_to_container(p)
    local t  = self.args[Tcelems[2]]
    local cT = self.container.T;               local cw, ch, cr = cT.w, cT.h, cT.r 
    if abs(cr) >= 0.1 then t.x, t.y = -cT.x, -cT.y; t_in(p, t); return t end                -- simpler: undo container translation 
    
    t.x, t.y = -0.5*cw, -0.5*ch;                t_in(p, t)                    -- center container
    r_in(p, cr)                                                               -- rotate about container center
    t.x, t.y = 0.5*cw - cT.x, 0.5*ch - cT.y;    t_in(p, t)                    -- shift back into container space
    return t
end

--_____________________________________________________
-- Main: decide if it collides with the input point
--_____________________________________________________
function GameObj:hit_test(point)
	if not self.container then return end
	local T, args, th = self.T, self.args, 0.1
	for _, c in ipairs(Tcelems) do args[c] = args[c] or {}; end

    local p, t, r  = args[Tcelems[1]], args[Tcelems[2]], args[Tcelems[3]]
	local buffer   = self.states.hover.is and self.cbuffer or 0                    -- hover buffer makes hitbox slightly larger
    local w, h, _r = T.w, T.h, T.r
    p.x, p.y = point.x, point.y                                                    -- start with input point
	
    if self.container ~= self then t = self:_to_container(p) end

	if abs(_r) < 0.1 then return _collide(p, T, buffer, self.debug_on) end
    local dx, dy = T.x + 0.5*T.w, T.y + 0.5*T.h;    r.cos, r.sin = cos(_r + 0.5*pi), sin(_r + pi/2)                             
    local x, y = p.x - dx, p.y - dy;                t.x, t.y     = y*r.cos - x*r.sin, y*r.sin + x*r.cos                       
    return _collide(p, T, buffer)
end

-----------------------------------------------------------------------------------
-- Set offset: Sets the offset of passed point in terms of this game_objects T.x and T.y
----------------------------------------------------------------------------------
function GameObj:set_offset(point, type)
    local args = self.args
    for _, v in ipairs(Toffsets) do args[v] = args[v] or {} end
	local p, t, dx, dy = args[Toffsets[1]], args[Toffsets[2]], 0, 0
	local cT, co, ho   = self.container.T, self.click_offset, self.hover_offset
	
    p.x, p.y  = point.x, point.y;               t.x, t.y  = -cT.w/2, -cT.h/2  -- start with input point, translate to container center
    t_in(p, t);                                 r_in(p, cT.r)                     -- rotate around container midpoint
	t.x, t.y = cT.w/2 - cT.x, cT.h/2 - cT.y;    t_in(p, t)                        -- translate back into container space
    dx, dy   = p.x - self.T.x, p.y - self.T.y
    if     type == "Click" then co.x, co.y = dx, dy
	elseif type == "Hover" then ho.x, ho.y = dx, dy end
end

----------------------------------------------------------------------------------
-- Stop Drag
------------------------------------------------------------------------------------
function GameObj:stop_drag()
    if not self.children.d_popup then return end
    for i, v in ipairs(self.POPUP) do if v == self.children.d_popup then pop(self.POPUP, i); break end end
    self.children.d_popup:remove()
    self.children.d_popup = nil
end

-----------------------------------------------------------------------------------------------------------------
-- Put focused cursor: Called by the CTRL to determine the position the cursor should be set to for this game_object
------------------------------------------------------------------------------------------------------------------
function GameObj:put_focused_cursor()
    local rcfg, T, cT    = self.rcfg, self.T, self.container and self.container.T or { x = 0, y = 0 }
	local tz, ts, cx, cy = rcfg.tile_size, rcfg.tile_scale, cT.x, cT.y
    local x, y, w, h, _n = T.x, T.y, T.w, T.h, tz*ts
	return (x + w*0.5 + cx)*_n, (y + h*0.5 + cy)*_n  -- center of game_object in container space, then scale to pixels
end

----------------------------------------------------------------------------------------------------
-- Set container
---------------------------------------------------------------------------------------------------
function GameObj:set_container(c) if self.children then for _, v in pairs(self.children) do v:set_container(c) end end; self.container = c end

------------------------------------------------------------------------------------------------------
-- Translate_container: 
-------------------------------------------------------------------------------------------------------
function GameObj:translate_container()
	if not self.container or self.container == self then return N end
	local T, rcfg  = self.container.T, self.rcfg
    local px = rcfg.tile_scale * rcfg.tile_size;      local w, h = T.w*px*0.5, T.h*px*0.5        
    LG.translate(w, h);                               LG.rotate(T.r or 0)
    LG.translate(-w + T.x*px, -h + T.y*px)            -- move to center, rotate, then move to top-left + position
	return Y
end

end
