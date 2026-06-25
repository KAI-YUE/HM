local abs = math.abs

local Y, N = true, false

return function(Actor)
-----------------------------
--- static move eligibility
----------------------------------
--- Helper: _move_eps
local function _move_eps(self, key)
    local motion = self.motion and self.motion[key]
    return motion and motion.snap or 0.0001
end

--- Helper: _has_velocity
local function _has_velocity(self)
    local v = self.velocity;                                    if not v then return N end
    return abs(v.x or 0) > _move_eps(self, "xy") or abs(v.y or 0) > _move_eps(self, "xy") or
        abs(v.w or 0) > _move_eps(self, "wh") or abs(v.h or 0) > _move_eps(self, "wh") or
        abs(v.r or 0) > _move_eps(self, "r") or abs(v.scale or 0) > _move_eps(self, "scale")
end

--- Helper: _transform_dirty
local function _transform_dirty(self)
    local T, VT = self.T, self.VT;                              if not T or not VT then return N end
    return abs((T.x or 0) - (VT.x or 0)) > _move_eps(self, "xy") or abs((T.y or 0) - (VT.y or 0)) > _move_eps(self, "xy") or
        abs((T.w or 0) - (VT.w or 0)) > _move_eps(self, "wh") or abs((T.h or 0) - (VT.h or 0)) > _move_eps(self, "wh") or
        abs((T.r or 0) - (VT.r or 0)) > _move_eps(self, "r") or abs((T.scale or 0) - (VT.scale or 0)) > _move_eps(self, "scale")
end

--- Helper: _layout_dirty
local function _layout_dirty(self) return self.card_layout_dirty or self.pawn_layout_dirty or self.card_layout_live or self.pawn_layout_live end

--- Helper: static move pending
function Actor:static_move_pending()
    if not (self.static_move or (self.config and self.config.static_move)) then return Y end
    if self.new_align or self.jitter or self.waypoint_T or self.pinch_transition then return Y end
    if _layout_dirty(self) or _has_velocity(self) or _transform_dirty(self) then return Y end
    return not self.stay
end

--- Helper: _update_center
function Actor:_update_center()
    local _center, T, r   = self.center, self.T, self.role
    _center.x, _center.y  = T.x + T.w/2, T.y + T.h/2
    
    local ro, pro = r and r.offset, self.prev_role_offset
    if ro and pro then pro.x, pro.y = ro.x, ro.y end
    self.new_align = N   -- Reset alignment flag
end

--__________________________________________
--- Main: move
--__________________________________________
function Actor:move(dt)
	local frame, FRS, r, Sa = self.FR, self.FRS, self.role, self.alignment
	if frame.f_m >= FRS.f_m then return end               	                   -- Prevent double-processing in the same frame
    if not self:static_move_pending() then frame.f_m = FRS.f_m; return N end
	
    frame.OLD_MAJOR, frame.MAJOR, frame.f_m = frame.MAJOR, nil, FRS.f_m
	if not self.created_on_pause and self.SET.pause then return end            -- Skip if pause (unless created during pause)

	self:align_to_major();                                                     -- align to major if needed
	local r_type, rmajor = r.role_type, r.major
	if     r_type == "Glued" and rmajor then self:glue_to_major(rmajor)        -- behavior per role type
    elseif r_type == "Minor" and rmajor then self:_minor_role(rmajor, FRS, dt) 
	elseif r_type == "Major"            then self:_major_role(dt)	   end
	if Sa and Sa.lr_clamp               then self:lr_clamp() end	           -- enforce alignment clamps

    self:_update_center()
    return Y
end

end
