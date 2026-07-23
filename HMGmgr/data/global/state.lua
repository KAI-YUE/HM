local rand = math.random
local StateDefs = require("HMGmgr.data.global.state_defs")

local Y, N = true, false

return function (GMgr)
-----------------------------
--- states and stages
----------------------------------
--- Helper: init_states_and_stages
function GMgr:init_states_and_stages()
    self.g_states,     self.stage_objs,  self.stages     = StateDefs.g_states, StateDefs.new_stage_objs(), StateDefs.stages
    self.args,         self.g_profile                   = {}, StateDefs.new_profiles()
    self.g_stage,      self.g_state                     = self.stages.title_page, self.g_states.splash
    self.t_interrupt,  self.state_comp,  self._vibr      = N, N, 0
end

--- Helper: init_parallax
function GMgr:init_parallax(room_w)
    local parallax  = self.parallax or {}
    local min_scale, max_scale = parallax.scale_min or 0.88, parallax.scale_max or 0.91

    parallax.scale_min, parallax.scale_max = min_scale, max_scale
    parallax.pivot_scale = min_scale + (max_scale - min_scale) * rand()
    parallax.pivot_x     = room_w and parallax.pivot_scale * room_w
    self.parallax        = parallax
end

end
