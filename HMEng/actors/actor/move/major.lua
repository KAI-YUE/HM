local abs      = math.abs
local sin, cos = math.sin, math.cos

local Y, N = true, false

return function(Actor)
-------------------------------------------------
--- glue_to_major: Strict Relationship with Major
-------------------------------------------------
function Actor:glue_to_major(major)
    local VT, mT, mVT = self.VT, major.T, major.VT

    VT.x, VT.y = mVT.x + 0.5*(mT.w - mVT.w), mVT.y
    VT.w, VT.h = mVT.w, mVT.h
    VT.r, VT.scale = mVT.r, mVT.scale

    self.pinch, self.T = major.pinch, mT
    self.shadow_parallax = major.shadow_parallax
end

-------------------------------------------------
-- Move with Major 
-------------------------------------------------
--- Helper: _generic_rot
local function _generic_rot(mVT, roffset, moffset, T, mT)
    local c,  s   = cos(mVT.r),       sin(mVT.r)
    local dx, dy  = roffset.x + moffset.x, roffset.y + moffset.y
    local dw, dh  = -T.w/2 + mT.w/2, -T.h/2 + mT.h/2
    local ox, oy  = dx - dw, dy - dh

    return ox*c - oy*s + dw, ox*s + oy*c + dh
end

---__________________
--- Main: move with major 
---__________________
function Actor:move_with_major(dt)
    local r = self.role;      if r.role_type ~= "Minor" then return end -- early bail out 
	
    local major_tab, j        = r.major:get_major(), self.jitter
	local major, rx, ry       = major_tab.major,     nil, nil
    local T,   VT,   mT, mVT  = self.T, self.VT,     major.T, major.VT
    local roffset,   moffset  = r.offset,            major_tab.offset

	self:move_with_jitter(dt)
	if r.r_bond == "Weak"    then rx, ry = roffset.x + moffset.x, roffset.y + moffset.y
	elseif abs(mVT.r) < 1e-4 then rx, ry = roffset.x + moffset.x, roffset.y + moffset.y
    else                          rx, ry = _generic_rot(mVT, roffset, moffset, T, mT)  end

	T.x, T.y = mT.x + rx, mT.y + ry                 
	if  r.xy_bond    == "Strong"  then VT.x, VT.y = mVT.x + rx, mVT.y + ry                            else self:move_xy(dt) end
	if  r.r_bond     == "Strong"  then VT.r = T.r + mVT.r + (j and j.r or 0)                          else self:move_r(dt, self.velocity) end
    if  r.scale_bond == "Strong"  then VT.scale = T.scale*(mVT.scale/mT.scale) + (j and j.scale or 0) else self:move_scale(dt) end
    if  r.wh_bond    == "Strong"  then VT.x = VT.x + (0.5*(1 - mVT.w/mT.w)*T.w); VT.w, VT.h = T.w * (mVT.w / mT.w), T.h * (mVT.h / mT.h) else self:move_wh(dt) end

	self:calculate_parallax()
end

-------------------------------------------------------
-- Movement easing
-------------------------------------------------------
--- Helper: _can_skip_minor_role_move
local function _can_skip_minor_role_move(self, r, cfg)
    if not self.stay then return N end
    if self.new_align or cfg.refresh_movement or self.jitter then return N end
    if r.xy_bond == "Weak" or r.r_bond == "Weak"             then return N end

    local ro, pro = r.offset or {}, self.prev_role_offset or {}
    return ro.x == pro.x and ro.y == pro.y
end

--- Helper: _minor_role
function Actor:_minor_role(rmajor, FRS, dt)
    if rmajor.FR.f_m < FRS.f_m then rmajor:move(dt) end  -- Ensure major is updated first
    self.stay = rmajor.stay

    local r, cfg  = self.role, self.config
    if _can_skip_minor_role_move(self, r, cfg) then return end
    self:move_with_major(dt)
end

--- Helper: _major_role
function Actor:_major_role(dt)
    self.stay = Y;                  self:move_with_jitter(dt)
    self:move_xy(dt);               self:move_r(dt, self.velocity)
    self:move_scale(dt);            self:move_wh(dt)
    self:calculate_parallax()
end

end
