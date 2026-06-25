local motion_utils = {}

local max, min = math.max, math.min

----------------------------------------------
--- Smooth damp
----------------------------------------------
function motion_utils.smooth_damp(x, v, target, smooth_time, max_speed, dt)
    if smooth_time < 1e-4 then return target, 0 end

    local omega   = 2/smooth_time
    local x_omega = omega*dt
    local _exp    = 1/(1 + x_omega + 0.48*x_omega*x_omega + 0.235*x_omega*x_omega*x_omega)

    local change, original_to = x - target, target
    local max_change = max_speed*smooth_time
    change = min(max(change, -max_change), max_change)
    target = x - change

    local temp = (v + omega*change)*dt
    v = (v - omega*temp)*_exp
    local out = target + (change + temp)*_exp

    if (original_to - x > 0) == (out > original_to) then out, v = original_to, 0 end
    return out, v
end

return motion_utils
