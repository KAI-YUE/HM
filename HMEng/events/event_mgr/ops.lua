local GEvent  = require("HMEng.events.game_event")
local push    = table.insert
local Y, N    = true, false
local r_elems = { "blocking", "completed", "time_done", "pause_skip" } 

return function (EventMgr)
---------------------------------------------
--- Enqueue event 
---------------------------------------------
function EventMgr:enqueue_event(params)
    params["SET"], params["_T"] = self.SET, self._T
    local Qs, queue, _GE = self.queues, params.queue or "base", GEvent(params)
    Qs[queue] = Qs[queue] or {}
    
    if params.urgent then push(Qs[queue], 1, _GE); return end
    push(Qs[queue], _GE)
end

----------------------------------------------
--- Update 
----------------------------------------------
function EventMgr:update(dt, forced)
    local args = self.args;     args.event_manager_update = args.event_manager_update or {}
    self.queue_timer = self.queue_timer + dt
    if self.queue_timer < self.queue_last_processed + self.queue_dt and not forced then return end

    self.queue_last_processed = self.queue_last_processed + (forced and 0 or self.queue_dt)
    for k, q in pairs(self.queues) do
        local i, blocked = 1, N
        while i <= #q do
            local results = args.event_manager_update
            for _, e in ipairs(r_elems) do results[e] = N end 
            if (not blocked or not q[i].blockable) then q[i]:handle(results) end
            -- if (not blocked or not q[i].blockable) then print(blocked); G.debugger.who_is_fn(q[i].func); q[i]:handle(results); print(G.debugger.tprint(results)) end
            if results.pause_skip then i = i + 1; goto continue end 
            if not blocked and results.blocking then blocked = Y end
            if results.completed and results.time_done then table.remove(q, i) else i = i + 1 end
            ::continue::
        end
    end
end

---------------------------------------------
--- Clear Queue 
---------------------------------------------
--- Helper: _wipe_queue
local function _wipe_queue(q)
    local i = 1
    while i <= #q do if not q[i].no_delete then table.remove(q, i)  else i = i + 1 end end
end

--- Main: clear queue 
function EventMgr:clear_queue(queue, exception)
    local Qs = self.queues
    if     not queue then for _, q in pairs(Qs) do  _wipe_queue(q) end; return                               -- clear all queues
    elseif exception then for _, q in pairs(Qs) do if q ~= exception then _wipe_queue(q) end end return end  -- clear all but exception
    _wipe_queue(Qs[queue])
end

end
