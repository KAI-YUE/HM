local max, min, sin, cos = math.max, math.min, math.sin, math.cos

local M = {}
---------------------------------------------------
--- Jitter canvas 
---------------------------------------------------
function M.jitter_canvas(gm, dt)
    local args, R, RO, SET, WT, FR = gm.args, gm._room, gm.ROOM_ORIG, gm.SET, gm.win_trans, gm.F.rumble
    local _rm, Cur, Ctrl, _T   = SET.C_static, gm.p_cursor, gm.CTRL, gm._T
    local _m, CT, RT, cpos, now    = 1.5*(_rm and 0 or 1), Cur.T, R.T, Ctrl.cursor_position, _T.real_s

	gm.vibr = R.jiggle or 0
	if not SET.scr_jitter or type(SET.scr_jitter) ~= "number" then SET.scr_jitter = _m or 50 end
	
	local shake_amt = _m * max(0, SET.scr_jitter - 30)/100 -- Base shake amount
	args.eased_cursor_pos = args.eased_cursor_pos or { x = CT.x, y = CT.y, sx = cpos.x, sy = cpos.y } -- Eased cursor pos

	local ec = args.eased_cursor_pos
	ec.x  = ec.x*(1 - 3*dt)  + 3*dt * (shake_amt*CT.x + (1 - shake_amt)*RT.w/2)
	ec.y  = ec.y*(1 - 3*dt)  + 3*dt * (shake_amt*CT.y + (1 - shake_amt)*RT.h/2)
	ec.sx = ec.sx*(1 - 3*dt) + 3*dt * (shake_amt*cpos.x + (1 - shake_amt)*WT.real_window_w/2)
	ec.sy = ec.sy*(1 - 3*dt) + 3*dt * (shake_amt*cpos.y + (1 - shake_amt)*WT.real_window_h/2)
	
	shake_amt = 2*_m*SET.scr_jitter/100                    -- Stronger shake amt
	if shake_amt < 0.05 then shake_amt = 0 end

	-- Jiggle + room offsets
	R.jiggle = (R.jiggle or 0) * (1 - 5*dt) * (shake_amt > 0.05 and 1 or 0)
	RT.r = (0.001*sin(0.3*now) + 0.002*R.jiggle*sin(39.913*now)) * shake_amt
    RT.x = RO.x + shake_amt * (0.015*sin(0.9*now) + 0.01*(R.jiggle*shake_amt)*sin(20*now) + (ec.x - 0.5*(RT.w + RO.x))*0.01)
	RT.y = RO.y + shake_amt * (0.015*sin(0.952*now) + 0.01*(R.jiggle*shake_amt)*sin(22*now) + (ec.y - 0.5*(RT.h + RO.y))*0.01)

	-- Vibration
	gm.vibr        = gm.vibr * (1 - 5*dt)
	gm.curr_vibr   = gm.curr_vibr or 0
	gm.curr_vibr   = min(1, gm.curr_vibr + gm._vibr + gm.vibr*0.2)
	gm._vibr = 0
	gm.curr_vibr = (1 - 15*dt)*gm.curr_vibr
	if not SET.rumble then gm.curr_vibr = 0 end

    local Gobj, _v = Ctrl.GAMEPAD, gm.curr_vibr
	if Gobj and FR then	Gobj:setVibration( 0.4*_v*FR, 0.4*_v*FR) end
end

return M