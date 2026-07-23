return function (EventMgr)
------------------------------------------------
--- init event_mgr attributes
------------------------------------------------
function EventMgr:init_event_mgr_attributes(gm)
    self.queues = { unlock = {}, base = {}, tutorial = {}, achievement = {}, shader_fx = {}, card_dealing = {}, save_menu_enter = {}, other = {} }
    local SET, _T = gm.SET, gm._T;      local now = _T.real_s
    
    self.queue_timer, self.queue_last_processed     = now, now
    self.SET, self._T, self.args, self.queue_dt = SET, _T, gm.args, 1/60
end

end
