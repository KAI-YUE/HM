local Tatt  = { "Fs", "anime_atlas", "a_atlas", "t_actors", "t_move_actors", "t_static_actors", "t_pending_move_actors", "t_anime", "t_drawable", "f_handler" }

local global_data = { "flags.flags", "settings.init", "state", "runtime", "scope" }

return function (GMgr)
for _, pkg in ipairs(global_data) do require("HMGmgr.data.global." .. pkg)(GMgr) end

-----------------------------
--- set_globals
----------------------------------
function GMgr:set_globals()
    self.Ver, self.seed, self.s_pitch = Ver, os.time(), 1
    for _, _t in ipairs(Tatt) do self[_t] = {} end              -- Table initialization 

    self:init_flags()
    self:init_setting_and_cfg()
    self:init_states_and_stages()
    self:init_misc_registries()
    self:init_audio_state()
end

end
