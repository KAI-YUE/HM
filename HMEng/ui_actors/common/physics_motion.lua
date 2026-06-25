local sin, cos, exp = math.sin, math.cos, math.exp
local min, max = math.min, math.max

local Y, N = true, false

local M = {}

---____________________________
--- main: damped_pendulum_offset
---______________________________________
function M.damped_pendulum_offset(cfg, t)
    cfg = cfg or {}
    local l, _f  = cfg.length or 3.5,   cfg.freq or 8
    local theta  = (cfg.theta or -1)    * exp(-(cfg.damp or 2)*t) * cos(_f*t)
    local pull   = (cfg.side_pull or 0) * exp(-3*t) * sin(_f*t)
    return { x = l*sin(theta) + pull, y = -l + l*cos(theta) }
end

---____________________________
--- main: spring_step_offset
---______________________________________
function M.spring_step_offset(cfg, step)
    cfg, step = cfg or {}, step or {}
    local l, theta = cfg.length or cfg.string_length or 7, step.theta or 0
    local drama    = cfg.drama or 1
    local x, y     = step.x or 0,  (step.y or 0) + l * (step.y_len or 0)

    if theta ~= 0 then
        x = x + l*sin(theta)*(step.swing_scale or 1)
        y = y + l*(1 - cos(theta))*(step.pendulum_y_scale or 0.18)
    end

    return x*drama, y*drama
end

---____________________________
--- main: parabola_offset
---______________________________________
function M.parabola_offset(cfg, progress)
    cfg = cfg or {}
    local p = max(0, min(1, progress or 0))
    local x = (cfg.from_x or 0) + ((cfg.to_x or 0) - (cfg.from_x or 0))*p
    local y = (cfg.from_y or 0) + ((cfg.to_y or 0) - (cfg.from_y or 0))*p - (cfg.arc_h or 0)*4*p*(1 - p)
    local r = (cfg.from_r or 0) + ((cfg.to_r or 0) - (cfg.from_r or 0))*p
    return x, y, r
end

---____________________________
--- main: chop_angle
---______________________________________
function M.chop_angle(cfg, t)
    cfg = cfg or {}
    local amp,  freq  = cfg.amp or 0.16, cfg.freq or 34
    local damp, phase = cfg.damp or 4.8, cfg.phase or 0
    return amp*exp(-damp*(t or 0)) * sin(freq*(t or 0) + phase)
end

---____________________________
--- main: roof_with_pivot_idle_offset
---______________________________________
function M.roof_with_pivot_idle_offset(cfg, t)
    cfg = cfg or {}
    t = t or 0
    local freq   = cfg.idle_freq or 2
    local theta  = (cfg.idle_angle or 0.08)*sin(freq*t)  + (cfg.idle_slow_angle or 0)*sin((cfg.idle_slow_freq or 0.5)*t + 0.7)

    local rel_x, rel_y  = cfg.pivot_rel_x or 0,                        cfg.pivot_rel_y or -0.5
    local x,     y      = rel_x*cos(theta) - rel_y*sin(theta) - rel_x, rel_x*sin(theta) + rel_y*cos(theta) - rel_y

    x = x + (cfg.idle_drift or 0) * sin(freq * t + 0.25)
    y = y + (cfg.idle_lift or 0) * 0.5 * (1 - cos(freq * t))
    return x, y, theta
end

return M
