local TabUtils = require("HMfns.utils.table_utils")
local wipe = TabUtils.wipe

local tt = "table"
local role_list = { "role_type", "offset", "major", "xy_bond", "wh_bond", "r_bond", "scale_bond", "draw_major" }

return function (Actor)
-------------------------------------------------------
-- Set Role 
-------------------------------------------------------
function Actor:set_role(args)
    local role, major, offset = self.role, args.major, args.offset
    if major and not major.set_role then return end                 -- Early bail out
    
    if offset and (type(offset) == tt and not (offset.y and offset.x)) or type(offset) ~= tt then args.offset = nil end
    for _, k in ipairs(role_list) do role[k] = args[k] or role[k] end
    if role.role_type == "Major" then role.major = nil end           -- update the reference
    if self.wake_move then self:wake_move() end
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(self) end
end

-------------------------------------------------------
-- Get Role 
-------------------------------------------------------
function Actor:get_major()
    local frame, mcache     = self.FR, self.cache.refresh_major
    local role, rmajor, lp  = self.role, self.role.major, self.layered_parallax

    if (role.role_type ~= "Major" and rmajor ~= self) and (role.xy_bond ~= "Weak" and role.r_bond ~= "Weak") then
        local fm = frame.MAJOR               -- First, does the major already have their offset precalculated for this frame?
        if fm and mcache then return fm end  -- early bail out 

        frame.MAJOR, self.temp_offs = frame.MAJOR or wipe(frame.OLD_MAJOR), wipe(self.temp_offs)
        local major, fm     = self.role.major:get_major(), frame.MAJOR
        fm.major, fm.offset = major.major, fm.offset or self.temp_offs
        local fmo, ro, mo   = fm.offset, role.offset, major.offset  -- Alias for offsets
        fmo.x, fmo.y        = mo.x + ro.x + lp.x, mo.y + ro.y + lp.y
        return fm
    end

    local args = self.args;        args.get_major      = args.get_major  or {}
    local am   = args.get_major;   am.major, am.offset = self, am.offset or {}
    local ams  = am.offset;        ams.x, ams.y        = 0, 0
    return am
end

end
