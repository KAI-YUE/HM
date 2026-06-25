-- functions/misc_functions/math_utils.lua
local math_utils = {}

local sqrt, cos, sin, pi = math.sqrt, math.cos, math.sin, math.pi
----------------------------------------------
--- Lerp
----------------------------------------------
function math_utils.lerp(per, max, min)	if per and max then return per*(max - (min or 0)) + (min or 0) end end

----------------------------------------------
--- Xf distance
----------------------------------------------
function math_utils.xf_dist(t1, t2, mid)
	local x = t1.x - t2.x + (mid and 0.5*(t1.w - t2.w) or 0)
	local y = t1.y - t2.y + (mid and 0.5*(t1.h - t2.h) or 0)
	return sqrt(x^2 + y^2)
end

---------------------------------------------
--- Vector Length, Vector Sub
---------------------------------------------
function math_utils.vec_len(t1) return math.sqrt(t1.x^2 + t1.y^2) end
function math_utils.vec_sub(t1, t2) return { x = t1.x - t2.x, y = t1.y - t2.y } end

------------------------------------------------
--- In-place translation of a point/transform
------------------------------------------------
function math_utils.vec_translate_inplace(_T, delta) _T.x, _T.y = (_T.x + delta.x) or 0, (_T.y + delta.y) or 0 end

---------------------------------------------------------------------------------------
--- In-place rotation by angle (radians), about origin, with 90° offset like original
----------------------------------------------------------------------------------------
function math_utils.vec_rotate_inplace(_T, angle)
	local _cos, _sin, _ox, _oy = -sin(angle), cos(angle), _T.x, _T.y
	_T.x = -_oy*_cos + _ox*_sin
	_T.y =  _oy*_sin + _ox*_cos
end

return math_utils

