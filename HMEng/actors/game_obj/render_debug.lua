local push_draw_trans = require("HMfns.systems.render").push_actor_draw_transform
local LG = love.graphics

return function (GameObj)
----------------------------------------------------------------------------------------------------
-- bound_me: Draw a bounding rectangle representing the transform of this game_object. Used in debugging.
----------------------------------------------------------------------------------------------------
-- Helper: _draw_debug_pivot, draw a pivot marker through the actor's visual transform.
local function _draw_debug_pivot(self)
	local pivot = self._debug_pivot
	if not (pivot and self.VT) then return end

	local screen_scale = self.rcfg.tile_scale * self.rcfg.tile_size * (self.VT.scale or 1)
	local radius       = 5 / screen_scale
	push_draw_trans(self, nil, self.draw_rotate or 0)
	LG.setColor(1, 0, 0, 1); LG.circle("fill", pivot.x, pivot.y, radius)
	LG.setColor(1, 1, 1, 1); LG.setLineWidth(1.5 / screen_scale); LG.circle("line", pivot.x, pivot.y, radius)
	LG.pop()
end

function GameObj:bound_me(args)
	if not self.debug.on then return end
	local T, rcfg, lw, col      = self.VT or self.T, self.rcfg, 1 + (self.states.focus.is and 1 or 0), { 1, 0, 0, 0.3 }
	local x, y, w, h, ts, scale = T.x, T.y, T.w, T.h, rcfg.tile_size, rcfg.tile_scale
    local tx, ty, r             = x*ts + w*ts*0.5, y*ts + h*ts*0.5, T.r

	LG.push();	          LG.scale(scale, scale)
	LG.translate(tx, ty)   -- center + rotate around middle of game_object
	LG.rotate(r);          LG.translate(-w*ts*0.5, -h*ts*0.5)
	if self.debug.val then LG.setColor(1, 1, 0, 1); LG.print(self.debug.val, w*ts, h*ts, nil, 1/scale) end

	-- if self.states.collide.is then col = { 0, 1, 0, 0.3 } end
	-- if self.states.focus.can  then col, lw = { 1, 1, 0.5, 1 }, 1 end

    if self == G._room  then col, lw = { 1, 0, 1, 0.3 }, 8 end
    -- if self == G.field  then col, lw = { 0.2, 0.35, 0.65, 0.5 }, 1 end

    -- local Chara = require("HMEng.chara")
    -- if self:is(Chara) then col, lw = { 0., 0.35, 0.95, 0.5 }, 5 end

    local ShaderFX = require("HMEng.actors.shader_fx")
    if self:is(ShaderFX) then col, lw = { 1., 1, 0.95, 0.5 }, 2 end

    local HMPanel = require("HMEng.ui_actors.hm_panel")
    if self:is(HMPanel) then col, lw = { 1., 1, 0.95, 0.5 }, 8 end

    -- -- local UIPanel     = require("HMEng.ui_actors.ui_panel")     = require("HMEng.ui_actors.ui_panel") require("HMEng.ui_actors.ui_panel")
    if self:is(UIPanel) then col, lw = { 0., 1, 0.95, 0.5 }, 2 end

    if args and args.col then col = args.col end
    if args and args.lw  then lw = args.lw  end

	LG.setLineWidth(lw);   LG.setColor(col)
	LG.rectangle("line", 0, 0, w*ts, h*ts)
	LG.pop()
	_draw_debug_pivot(self)
end

end
