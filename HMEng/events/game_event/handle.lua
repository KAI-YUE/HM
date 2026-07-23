local Y, N = true, false

return function (GEvent)
---------------------------------------
--- Handle 
---------------------------------------
function GEvent:handle(_r)
    _r.blocking, _r.completed = self.blocking, self.complete
    if not self.created_on_pause and self.SET.pause then _r.pause_skip = Y; return end      -- Skip if pause and created_on_pause is false
    if not self.start_timer then self.time = self._T[self.t_type]; self.start_timer = Y end -- Initialize the timer only once

    local  _t = self.trigger
    if     _t == "after"     then self:_after_trigger(_r)
    elseif _t == "ease"      then self:_ease_trigger(_r)
    elseif _t == "before"    then self:_before_trigger(_r)
    elseif _t == "immediate" then self:_immediate_trigger(_r) end
    if _r.completed          then self.complete = true end
end

-------------------------------
-- Handle "after" trigger
-------------------------------
function GEvent:_after_trigger(_r)
    local now = self._T[self.t_type]
    if now < self.time + self.delay then return end
    _r.time_done, _r.completed = Y, self.func()
end

------------------------------
-- Handle "ease" trigger
------------------------------
-- Helper: apply easing
function GEvent:_ease_to(_p)
    local easing_function
    if self.ease.type == "lerp"           then  -- for now do nothing   
    elseif self.ease.type == "elastic"    then _p = -math.pow(2, 10*_p - 10) * math.sin((_p*10 - 10.75)*2*math.pi/3)
    elseif self.ease.type == "quad"       then _p = _p^2
    elseif self.ease.type == "cubic"      then _p = _p * _p * _p
    elseif self.ease.type == "sine"       then _p = 0.5 * (1.0 - math.cos(math.pi * _p))
    elseif self.ease.type == "smoothstep" then _p = _p * _p * (3.0 - 2.0 * _p) end

    easing_function = function() return _p*self.ease.start_val + (1 - _p)*self.ease.end_val end
    self.ease.ref_table[self.ease.ref_value] = self.func(easing_function())
end

--___________________
-- Main 
--___________________
function GEvent:_ease_trigger(_r)
    local ease, now, _d = self.ease, self._T[self.t_type], self.delay
    if not ease.start_time then
        ease.start_time, ease.end_time = now, now + _d
        if ease.start_val == nil then ease.start_val = ease.ref_table[ease.ref_value] end
    end
    if self.complete then return end

    if ease.start_val == nil or ease.end_val == nil then
        self.complete, _r.completed, _r.time_done = Y, Y, Y
        return
    end
    
    local _s, _e = ease.start_time, ease.end_time
    if now <= _e then local _p = (_e - now)/(_e - _s); self:_ease_to(_p) return end

    ease.ref_table[ease.ref_value] = self.func(ease.end_val)
    self.complete, _r.completed, _r.time_done = Y, Y, Y
end

-----------------------------------------------
-- Handle "before" trigger
----------------------------------------------
function GEvent:_before_trigger(_r)
    if not self.complete then _r.completed = self.func() end
    local now, _d = self._T[self.t_type], self.delay
    if now >= self.time + _d then _r.time_done = Y end
end

-----------------------------------------------
-- Handle "immediate" trigger
-----------------------------------------------
function GEvent:_immediate_trigger(_r) _r.completed, _r.time_done = self.func(), Y end

end
