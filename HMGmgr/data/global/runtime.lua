local Y, N = true, false

return function (GMgr)
-----------------------------
--- runtime registries
----------------------------------
--- Helper: init_misc_registries
function GMgr:init_misc_registries()
    local selfF = self.F

    --- _T, frames
    -- real_s is wall-clock UI/cosmetic time; game_s is scaled gameplay/simulation time.
    self._T       = { game_s = 0, real_s = 0, shaders_s = 0, session_s = 0, bg_s = 0 }
    self.FRS      = { f_dr = 0, f_m = 0 }   -- frames draw & move
    self.g_cache  = { refresh_major = 0 }

    self.ID = 1
    self.keybind_mapping  = require("core.io.controller_key_sheet").map
    self.button_mapping   = { a = selfF.swap_AB_btns and "b" , b = selfF.swap_AB_btns and "a" , y = selfF.swap_XY_btns and "x" , x = selfF.swap_XY_btns and "y"  }

    -- game registries
    self.UI, self.debug  = { overlay_tut = nil,  REFRESH_ALERTS = nil, suspended = nil }, { on = N } -- suspended: skip 1 frame;
    self.Zones, self.R   = {}, { ACTOR = {}, ALERT = {}, ANIM_DECORATOR = {}, BOARDZONE = {}, CARD = {}, CARDZONE = {}, CHARA = {}, GOBJ  = {}, TMAP = {}, SHADERFX = {}, SPRITE = {}, PAWN = {}, TERRAINPAWN = {}, POPUP = {}, UIPANEL = {},    }
    self.registry_scope  = "run"
    self.ScopeR          = { run = {}, menu = {}, transient = {}, system = {} }
end

-----------------------------
--- audio state
----------------------------------
--- Helper: init_audio_state
function GMgr:init_audio_state()
    local SET = self.SET
    SET.s_snd       = { volume = 100, music_volume = 5, SE_volume = 30, voice_volume = 50, dialogue_voice = Y }
    self.audio_sync = { step_t = 1/30,  tracks = {},  current_key = "", elapsed = 0,
        prev_level = 0,  level = 0,      delta = 0,   frame       = -1 }
end

end
