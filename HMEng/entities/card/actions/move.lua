local Actor      = require("HMEng.actors.actor")
local GameObj    = require("HMEng.actors.game_obj")
local MathUtils  = require("HMfns.utils.math.math_utils")

local t_in, r_in = MathUtils.vec_translate_inplace, MathUtils.vec_rotate_inplace
local rand, exp  = math.random, math.exp
local max        = math.max

local Y, N = true, false

return function (Card)
----------------------------------------
--- Move 
----------------------------------------
function Card:move(dt)
    Actor.move(self, dt)
    local chpop_up = self.children.h_popup
    if chpop_up then chpop_up:set_alignment(self:align_h_popup()) end
end

------------------------------------------------------
--- Drag
-----------------------------------------------------
local function _cursor_target(self, Ctrl, offset)
    local cpos, args     = Ctrl.cursor_position, self.args
    local tsize, tscale  = self.rcfg.tile_size,  self.rcfg.tile_scale
    local norm, cT       = tsize * tscale,       self.container.T

    local p, t = args.card_drag_cursor_trans or {}, args.card_drag_translation or {}
    args.card_drag_cursor_trans, args.card_drag_translation = p, t

    p.x, p.y = cpos.x/norm, cpos.y/norm
    t.x, t.y = -cT.w/2,     -cT.h/2

    t_in(p, t)
    r_in(p, cT.r)
    t.x, t.y = cT.w/2 - cT.x, cT.h/2 - cT.y
    t_in(p, t)

    offset = offset or self.click_offset
    return p.x - offset.x, p.y - offset.y
end

--- Helper: hand drag release y 
local function _battle_owns_hand_drag(self)
    local battle = self.gm and self.gm.run_loop and self.gm.run_loop.battle
    return battle and battle.active
end

local function _hand_drag_release_y(self)
    if _battle_owns_hand_drag(self) then return end
    local zone = self.zone
    if not (zone and zone.is_hand and zone:is_hand()) then return end

    local offset = -1*zone.T.h
    return zone.T.y + offset, zone
end

--- Helper: auto release drag 
local function _auto_release_drag(self, Ctrl, zone)
    if not self.states.drag.is then return end

    local mass, response  = self.drag_mass, self.drag_response
    local smooth_time     = self.drag_release_smooth_time or max(self.motion.xy.smooth_time, mass/response)
    self.waypoint_landing = { smooth_time = smooth_time, max_speed = self.drag_release_max_speed }

    self:stop_drag()
    self.states.drag.is = N

    local dr = Ctrl and Ctrl.dragging
    if dr and dr.target == self then dr.target, dr.handled = nil, Y end

    local cdown = Ctrl and Ctrl.cursor_down
    if cdown and cdown.target == self then cdown.target, cdown.handled = nil, Y end

    local ro = Ctrl and Ctrl.released_on
    if ro then ro.target, ro.handled = nil, Y end

    if zone and zone.align_cards then zone:align_cards() end
end

------------------------------------------------------------
--- drag 
------------------------------------------------------------
function Card:drag(Ctrl, offset)
    local drc = self.states.drag.can;       if not drc and not offset then return end
    if self.states.dealing then self.states.dealing.is = N end

    local T,  args  = self.T, self.args
    local tx, ty    = _cursor_target(self, Ctrl, offset)
    local gm, mass  = self.gm, self.drag_mass

    if mass <= 0 then
        T.x, T.y = tx, ty
    else
        local dt, drag  = (gm.real_dt) or (1/60), args.card_drag or {}
        args.card_drag  = drag

        local response  = self.drag_response
        local k         = 1 - exp(-(response / mass) * dt)
        T.x, T.y        = T.x + (tx - T.x)*k, T.y + (ty - T.y)*k
        drag.target_x, drag.target_y = tx, ty
    end

    self.new_align = Y
    local release_y, hand_zone = _hand_drag_release_y(self)
    if release_y and T.y < release_y then T.y = release_y; _auto_release_drag(self, Ctrl, hand_zone) end

    GameObj.drag(Ctrl, self)
end

-----------------------------------------------------
--- stop drag 
-----------------------------------------------------
function Card:stop_drag()
    local battle = self.gm and self.gm.run_loop and self.gm.run_loop.battle
    if battle and battle.active then require("HMGplay.run_flow.game_run.battle").snap_dragged_card(battle, self) end
    self.args.card_drag = nil
    GameObj.stop_drag(self)
end

------------------------------------------------------
--- Jitter me
-----------------------------------------------------
function Card:jitter_me(scale, rot_amount)
    local gm, r = self.gm, 0;               gm._vibr = gm._vibr + 0.4
    if rot_amount then r = 0.4*(rand()>0.5 and 1 or -1)*rot_amount else r = (rand()>0.5 and 1 or -1)*0.16 end
    scale = scale and scale*0.4 or 0.11
    Actor.jitter_me(self, scale, r)
end

end
