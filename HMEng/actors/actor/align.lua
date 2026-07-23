local _sfind = string.find
local tt = "table"

return function (Actor)
-------------------------------------------------------
--  Set Alignment
-------------------------------------------------------
-- Helper: register role 
function Actor:_reg_role(args)
    self:set_role({
        role_type   = "Minor",         major = args.major,
        xy_bond     = args.bond        or args.xy_bond or "Weak",
        wh_bond     = args.wh_bond     or self.role.wh_bond,
        r_bond      = args.r_bond      or self.role.r_bond,
        scale_bond  = args.scale_bond  or self.role.scale_bond })
end

-- Helper: validate the offset 
local function _valid_offset(o) return o and (type(o) == tt and not (o.y and o.x)) or type(o) ~= tt end
--_____________________________________________
--- Main
--_____________________________________________
function Actor:set_alignment(args)
    local args = args or {}
    local offset, alignment, al = args.offset, self.alignment, { "type", "offset", "lr_clamp" }

    if args.major then self:_reg_role(args) end
    if _valid_offset(offset) then args.offset = nil end
    for _, k in ipairs(al) do alignment[k] = args[k] or alignment[k] end
end

-------------------------------------------------------
--  Align to major
-------------------------------------------------------
--- Helper: init type list 
local function init_type_list(alignment)
    local _t = alignment.type
    local type_list  = { a = (_t == "a") }
    local valid_cand = { "m", "c", "b", "t", "l", "r", "i" }
    ---@diagnostic disable-next-line: assign-type-mismatch
    for _, k in ipairs(valid_cand) do type_list[k] = _sfind(_t, k) end
    return type_list
end

---____________________
--- Main: align_to_major
---_____________________
function Actor:align_to_major()
    local alignment, role     = self.alignment,      self.role
    local offset,    poffset  = alignment.offset,    alignment.prev_offset
    local type,      ptype    = alignment.type,      alignment.prev_type
    local rmajor,    roffset  = role.major,          role.offset
    local rmT,   T,  MT       = rmajor and rmajor.T, self.T, self.Mid.T

    if type ~= ptype then alignment.type_list = init_type_list(alignment) end
    local tlist = alignment.type_list
    if (poffset.x == offset.x) and (poffset.y == offset.y) and (ptype == type) then return end  -- Early bail out  < nothing has changed >

    self.new_align = true
    if self.wake_move then self:wake_move() end
    if type ~= ptype then alignment.prev_type = alignment.type end
    if tlist.a or not rmajor then return end                                               -- Absolute: no alignment
    if tlist.m then roffset.x = rmT.w/2 - (MT.w)/2 + offset.x - MT.x + T.x end           -- Middle: mid x
    if tlist.c then roffset.y = rmT.h/2 - (MT.h)/2 + offset.y - MT.y + T.y end           -- Center: mid y
    if tlist.b then local h = tlist.i and T.h or 0; roffset.y = offset.y + rmT.h - h end   -- "Bottom" "Inside or"
    if tlist.r then local w = tlist.i and T.w or 0; roffset.x = offset.x + rmT.w - w end   -- "Right edge"
    if tlist.t then local h = tlist.i and 0 or T.h; roffset.y = offset.y - h end           -- "Top"
    if tlist.l then local w = tlist.i and 0 or T.w; roffset.x = offset.x - w end           -- "Left"
    
    roffset.x, roffset.y   = roffset.x or 0, roffset.y or 0                                -- Update offsets & alignment
    T.x,       T.y         = rmT.x + roffset.x, rmT.y + roffset.y
    alignment.prev_offset  = alignment.prev_offset or {}
    poffset.x, poffset.y   = offset.x, offset.y
end

end
