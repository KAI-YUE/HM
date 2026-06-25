return function (GMgr)
-----------------------------
--- new run
----------------------------------
--- Helper: tells if we are in a normal game
function GMgr:is_normal_game() 
    local game = self.GAME 
    if not game then return N end
    if game.won or game.seeded or game.challenge then return N else return Y end 
end

-----------------------------
--- _new_run
----------------------------------
function GMgr:_new_run()
    local game, P, SET, Fs = self.GAME, self.g_profile, self.SET, self.Fs
    if self:is_normal_game() then P[SET.profile].high_scores.current_streak.amt = 0 end
    self:save_settings();         SET.current_setup = "New Run"
    game.viewed_back = nil;       self.run_setup_seed = game.seeded;        self.challenge_tab = game.challenge and game.challenge_tab 
    self.forced_seed = nil;       self.setup_seed     = nil;                self.forced_stake  = game.stake
    
    if game.seeded then self.forced_seed = game.pseudorandom.seed end
    if self.g_stage == self.stages.run_game then Fs.begin_new_run(self) end
    self.forced_stake, self.challenge_tab, self.forced_seed = nil, nil, nil
end 

-----------------------------
--- start_run
----------------------------------
function GMgr:start_run(args)
    return self.Fs.init_run(self, args)
end

end
