local TextFX  = require("HMEng.ui_actors.card_textfx")
local TMR     = require("HMfns.systems.timer")
local SND     = require("HMfns.utils.sound_utils")

local sin, exp        = math.sin, math.exp
local min, max, abs   = math.min, math.max, math.abs
local push            = table.insert
local modulate_sound  = SND.start_modulate_sound
local tick_gc         = TMR.tick_gc

local Y, N = true, false

return function (GMgr)
-----------------------------
--- Update 
----------------------------------
--- Helper: update clock 
function GMgr:update_clock(SET, dt)
    tick_gc(nil, nil, Y)
    local _T = self._T                                         -- Smooth out the dts to avoid any big jumps
    _T.real_s = _T.real_s + dt;                                 _T.shaders_s = SET.C_static and 300 or _T.real_s
    _T.session_s = _T.session_s + dt;                         _T.bg_s = self._T.bg_s + dt*(self.args.spin and self.args.spin.amount or 0)
    self.real_dt = dt;                                        self.E_MANAGER:update(dt)

    if dt > 0.05 then print("LONG DT @ "..math.floor(self._T.real_s)..": "..dt) end
    if SET.pause then dt = 0 end

    local gst, gstg, sts, stgs = self.g_state, self.g_stage, self.g_states, self.stages
    if gst ~= self.acc_state then self.accelerate = 0 end
    self.acc_state = gst

    if (gst == sts.hand_played) or (gst == sts.new_round) then self.accelerate = min( (self.accelerate or 0) + dt*0.2*SET.g_speed, 16 )
    else self.accelerate = 0 end

    SET.sf       = (gstg == stgs.run_game and not SET.pause and not self.screenwipe) and SET.g_speed or 1
    SET.sf       = SET.sf + max(0, abs(self.accelerate) - 2)
    self.game_dt = dt*(SET.sf)
    _T.game_s    = _T.game_s + self.game_dt
    return dt
end

--- Helper: update color 
function GMgr:update_color() end

--- Helper: adhoc update 
function GMgr:adhoc_update(gst, sts, dt)
    if     gst == sts.select_hand   then if (not self.hand.cards[1]) and self.deck.cards[1] then  self.g_state, self.state_comp = sts.draw_hand, N else self:update_selecting_hand(dt) end 
    elseif gst == sts.shop          then self:update_shop(dt)
    elseif gst == sts.hand_played   then self:update_hand_played(dt) 
    elseif gst == sts.draw_hand     then self:update_draw_to_hand(dt)
    elseif gst == sts.draw_unsorted then self:update_draw_unsorted(dt)
    elseif gst == sts.new_round     then self:update_new_round(dt) 
    elseif gst == sts.round_eval    then self:update_round_eval(dt) 
    elseif gst == sts.game_over     then self:update_game_over(dt) end
end

--- Helper: Update steam 
function GMgr:update_steam()
    local STEAM, _T = self.STEAM, self._T;                    if not STEAM then return end
    local SC = STEAM.send_control;                            if not SC.update_queued then return end
    if not SC.force and SC.last_sent_stage == self.g_stage and SC.last_sent_time >= _T.session_s - 120 then return end

    if STEAM.userStats.storeStats() then
        SC.force = N
        SC.last_sent_stage = self.g_stage
        SC.last_sent_time = _T.session_s
        SC.update_queued = N
    else
        self.debug.val = "UNABLE TO STORE STEAM STATS"
    end
end

--- Helper: Update save dat
function GMgr:update_save_dat()
    local FH = self.f_handler;          if not FH or not FH.update_queued then return end

    local SET, _T,  F  = self.SET, self._T, self.F
    local invalid_FH   = not FH.force and FH.last_sent_stage == self.g_stage
    local paused       = not FH.run or (FH.last_sent_pause == SET.pause)

    if invalid_FH and paused and (FH.last_sent_time and FH.last_sent_time > (_T.session_s - F.save_timer)) then return end
    
    local SC, profile, args = self.SaveMgr.channel, SET.profile, self.args
    local slot_idx = SET.slot_idx or args.save_slot_id or 1

    if FH.metrics  then SC:push({ type = "save_metrics", save_metrics = args.save_metrics })    end
    if FH.progress then SC:push({ type = "save_progress", save_progress = args.save_progress, slot_idx = slot_idx }) end
    if FH.settings then SC:push({ type = "save_settings", save_settings = SET, profile_num = profile, save_profile = self.g_profile[profile], save_data = SET.save_data }) end
    if FH.run      then
        SC:push({ type = "save_run", save_table = args.save_slot_data or args.save_run, save_meta = args.save_slot_meta,
            slot_id = args.save_slot_id, user_name = args.save_slot_user_name, profile_num = profile, save_data = SET.save_data })
        args.save_slot_data, args.save_slot_meta = nil, nil
        args.save_slot_id, args.save_slot_user_name = nil, nil
        self.saved_game = nil
    end

    FH.force, FH.last_sent_stage     = N, self.g_stage
    FH.last_sent_time,  FH.run       = _T.session_s, N
    FH.last_sent_pause, FH.settings  = SET.pause, N
    FH.progress, FH.metrics          = N, N
end

--- Helper: actor should move
local function actor_should_move(v) return (not v.static_move_pending) or v:static_move_pending() end

--- Helper: mark actor move pending
function GMgr:mark_actor_move_pending(actor)
    if not actor or actor.REMOVED or actor.move_pending then return end
    local pending = self.t_pending_move_actors;                 if not pending then return end
    actor.move_pending = Y;                                     push(pending, actor)
end

--- Helper: mark zone layout dirty
function GMgr:mark_zone_layout_dirty(zone, kind)
    if not zone then return end
    if kind ~= "pawn" then zone.card_layout_dirty = Y end
    if kind ~= "card" then zone.pawn_layout_dirty = Y end
    self:mark_actor_move_pending(zone)
end

--- Helper: move actor
local function move_actor(v, FRS, dt) if v.FR.f_m < FRS.f_m then v:move(dt) end end

--- Helper: move pending actors
local function move_pending_actors(gm, FRS, dt)
    local pending = gm.t_pending_move_actors
    for i = #pending, 1, -1 do
        local v = pending[i]
        pending[i] = nil
        if v and v.move_pending then
            v.move_pending = N
            if not v.REMOVED and actor_should_move(v) then move_actor(v, FRS, dt); if actor_should_move(v) then v:wake_move() end end
        end
    end
end

--- Helper: poll static actors
local function poll_static_actors(gm, FRS, dt)
    for _, v in pairs(gm.t_static_actors) do if not v.move_pending and actor_should_move(v) then move_actor(v, FRS, dt); if actor_should_move(v) then v:wake_move() end end end
end

-----------------------------
--- update
----------------------------------
function GMgr:update(dt)
    local FRS, SET, Fs = self.FRS, self.SET, self.Fs;        FRS.f_m = FRS.f_m + 1
    modulate_sound(self, dt);                                Fs.jitter_canvas(self, dt)
    
    dt = self:update_clock(SET, dt);                        
    local gst, gstg, sts, stgs = self.g_state, self.g_stage, self.g_states, self.stages
    self:update_color();                                     
    
    local ET, rdt, sf = self.exp_times, self.real_dt, SET.sf
    self:adhoc_update(gst, sts, dt)
    
    for k, v in pairs(self.t_anime) do v:animate(rdt*sf) end

    local safe_dt = min(1/30, rdt)                          
    
    for k, v in pairs(self.t_move_actors) do move_actor(v, FRS, safe_dt) end
    move_pending_actors(self, FRS, safe_dt)
    if FRS.f_m % 8 == 0 then poll_static_actors(self, FRS, safe_dt) end
    if self.camera then self.camera:update(safe_dt) end
    for k, v in pairs(self.t_actors) do v:update(dt*sf); v.states.collide.is = N end
    
    self.CTRL:update(self, rdt);                             
    self:update_steam()
    self:update_save_dat()
end

end
