local TabUtils = require("HMfns.utils.table_utils")
local LG = love.graphics

local wipe = TabUtils.wipe

local M = {}

--- Helper: _orig
local function _orig() return { x = 0, y = 0 } end

-------------------------------------------------------------
--- push actor draw transform
-------------------------------------------------------------
function M.push_actor_draw_transform(actor, scale, rotate, offset, draw_state)
	LG.push();              local rcfg = actor.rcfg
    LG.scale(rcfg.tile_scale*rcfg.tile_size)
    
    local scale, rotate   = scale or 1, rotate or 0
	local VT,  o,  p      = actor.VT,   offset or _orig(), actor.layered_parallax or (actor.parent and actor.parent.layered_parallax) or _orig()
    local x, y, w, h, _s  = VT.x, VT.y, VT.w, VT.h, VT.scale
    local ds             = draw_state or actor
    
    local sx,  sy   = _s*scale*(ds.draw_scale_x or 1), _s*scale*(ds.draw_scale_y or 1)
	local dx,  dy   = ds.draw_offset_x or 0,           ds.draw_offset_y or 0
    local ax,  ay   = ds.draw_anchor_x or 0.5,         ds.draw_anchor_y or 0.5
    local shx, shy  = ds.draw_shear_x or 0,            ds.draw_shear_y or 0

	LG.translate(x + w*ax + o.x + p.x + dx, y + h*ay + o.y + p.y + dy)
	if VT.r ~= 0 or actor.jitter or rotate then LG.rotate(VT.r + rotate) end
    if shx ~= 0 or shy ~= 0 then LG.shear(shx, shy) end
    
	LG.translate(-w*sx*ax, -h*sy*ay)
	LG.scale(sx, sy)
end

------------------------------------------------------
--- On shadow toggle 
------------------------------------------------------
function M.shadows_toggle(gm, args)
    gm.SET.s_graphics.shadows = (args.to_key == 1 and "On") or "Off"
    gm:save_settings()
end

--------------------------------------------------
--- Add an object to the game manager drawable  
--------------------------------------------------
function M.enqueue_drawable(tab, obj) if not obj then return end;  table.insert(tab, obj) end
function M.add_to_drawable(gm, obj)   M.enqueue_drawable(gm.t_drawable, obj) end

---------------------------------------------
--- Wipe Drawable 
--------------------------------------------
function M.wipe_drawable(gm) gm.t_drawable = wipe(gm.t_drawable) end

return M
