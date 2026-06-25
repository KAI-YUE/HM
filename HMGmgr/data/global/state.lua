local rand = math.random

local Y, N = true, false

return function (GMgr)
-----------------------------
--- states and stages
----------------------------------
--- Helper: init_states_and_stages
function GMgr:init_states_and_stages()
    --- States
    self.g_states = {    idle = 0, select_hand = 1,    hand_played = 2, draw_hand = 3,  draw_unsorted = 4, game_over = 5,   shop   = 6,
        viewing_deck = 7, round_eval = 8, menu = 11,   new_round = 12,   splash      = 13 }

    self.args,         self.stage_objs,  self.stages     = {}, { {}, {}, {} }, { title_page = 1, run_game = 2, run_tut = 3 }
    self.g_stage,      self.g_state,     self.g_profile  = self.stages.title_page, self.g_states.splash, { {}, {}, {} }
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
