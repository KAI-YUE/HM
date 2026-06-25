--                      1         2           3             4             5          6             7          8      9         10
local init_list = { "trigger", "blocking", "blockable", "start_timer", "delay", "no_delete", "pause_force", "SET", "timer", "_T"}

local ti = "immediate"
local Y, N = true, false 

return function (GEvent)
-----------------------------------------------
-- init event attributes
-----------------------------------------------
--- Helper: initialize ease type
function GEvent:_init_ease(cfg)
    local _t, rt, rv = cfg.ease or "lerp", cfg.ref_table, cfg.ref_value
    local sv, ev     = rt[rv], cfg.ease_to
    self.ease = { type = _t, ref_table = rt, ref_value = rv, start_val = sv, end_val = ev, start_time = nil, end_time = nil }
    self.func = cfg.func or function(t) return t end
end

--- Helper: initialize condition type
function GEvent:_init_condition(cfg)
    local rt, rv, sv = cfg.ref_table, cfg.ref_value, cfg.start_val
    self.condition = { ref_table = rt, ref_value = rv, stop_val = sv }
    self.func = cfg.func or function() return rt[rv] == sv end
end

--_____________________________________
--- Main: init the attributes
--_____________________________________
function GEvent:init_event_attributes(cfg)
    --                     1   2  3  4  5  6          7          8          9        10
    local default_vals = { ti, Y, Y, N, 0, N, cfg.SET.pause , cfg.SET, "game_s", cfg._T}
    for i, l in ipairs(init_list) do if cfg[l] ~= nil then self[l] = cfg[l] else self[l] = default_vals[i] end end

    self.blocking = self.blockable -- unify the blocking logic 
    self.complete, self.func = N, cfg.func or function() return true end
    self.created_on_pause    = self.pause_force
    if self.created_on_pause and not cfg.timer then self.timer = "real_s" end
    self.t_type, self.time   = self.timer, cfg._T[self.timer]
    
    if self.trigger == "ease"      then self:_init_ease(cfg) end      -- ease trigger
    if self.trigger == "condition" then self:_init_condition(cfg) end -- condition trigger
end

end