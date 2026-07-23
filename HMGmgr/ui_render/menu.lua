local GameObj      = require("HMEng.actors.game_obj")
local Actor        = require("HMEng.actors.actor")
-- local UIPanel     = require("HMEng.ui_actors.ui_panel")      = require("HMEng.ui_actors.ui_panel")
local Deck, C      = require("HMEng.entities.deck"), require("HMfns.animate.color.color_const")
local Card         = require("HMEng.entities.card")
local CardZone     = require("HMEng.entities.board.cardzone")
local LG           = love.graphics

local TabUtils = require("HMfns.utils.table_utils")
local SndUtils = require("HMfns.utils.sound_utils")
local TweenC   = require("HMfns.animate.transitions.tween_color")
local Unlock   = require("HMfns.systems.unlocks")

local play_clip    = SndUtils.play_clip
local h_unlock_req = Unlock.handle_unlock_request
local _pick, rand  = TabUtils.random_pick, math.random 
local push         =  table.insert

local ck, cw, co   = C.BLACK, C.WHITE, C.ORANGE
local crd, cgld    = C.RED, C.GOLD

local _ta    = "after"
local Y, N   = true, false

return function (GMgr)
-----------------------------
--- Title Page
----------------------------------
function GMgr:title_page(_ctx)
    local _T, ST, STG, Fs  = self._T, self.g_states, self.stages, self.Fs
    local SET, EM, AA, R, RA  = self.SET, self.E_MANAGER, self.a_atlas, self._room, self._room_r
    local RT, PR  = R.T, self.g_profile

    if _ctx ~= "splash" then _T.real_s, _T.game_s = 12, 12       -- Skip the timer to xx seconds for all shaders that need it
    else Fs.reset_snd_states(ST.menu, self.snd_src) end                         -- keep all sounds that came from splash screen
    
    self:prep_stage(STG.title_page, STG.menu, Y)                  -- Prepare the title page, reset the default deck
    self.GAME.selected_back = Deck(self, G.CMod.b_red)

    if (not SET.tutorial_complete) then SET.tutorial_complete = Y end

    Fs.shadows_toggle(self, { to_key = (SET.s_graphics.shadows == "On" and 1) or 2 })
    -- Fs.tween_background_palette(self, { new_color = ck, contrast = 1 })
    Fs.toast_unlock_ntf(self)

    Fs.init_screen_pos(self)
    EM:enqueue_event({ trigger = _ta, delay = 0., blockable = N, blocking = N, func = function() return Fs.launch_title_page(self, _ctx == "title" and "title" or "preparation") end })
    
    for k, v in pairs(PR[SET.profile].career_stats) do h_unlock_req(self, { type = "career_stat", statname = k }) end
    h_unlock_req(self, { type = "blind_discoveries" })           -- Do all career stat unlock checking here as well
    
    Fs.set_discoveries(self);               Fs.set_progress(self)            
    self.UI.REFRESH_ALERTS = Y;             return Y
end

-----------------------------
--- Prep stage: create room and room_attach 
----------------------------------
function GMgr:prep_stage(new_stage, new_state, new_game_obj)
    local Ctrl, STGS, STS, SET, rcfg = self.CTRL, self.stages, self.g_states, self.SET, self.rcfg
    for k, v in pairs(Ctrl.locks) do Ctrl.locks[k] = nil end
    if new_game_obj then self:init_game_manager() end
    
    self.g_stage, SET.pause       = new_stage or STGS.title_page, N
    self.g_state, self.state_comp = new_state or STS.menu, N
    local x, y, w, h = rcfg.r_pad_w, rcfg.r_pad_h, rcfg.tile_w, rcfg.tile_h

    self._room = GameObj(self, { T = { x = x, y = y, w = w, h = h } })
    local R   = self._room;             R.jiggle, R.states.drag.can = 0, N
    R:set_container(R)
    self:init_parallax(R.T.w)

    self._room_r = Actor(self, { T = { x = 0, y = 0, w = w, h = h } })
    local RA = self._room_r;            RA.states.drag.can = N
    RA:set_container(R);                love.resize(LG.getWidth(), LG.getHeight())
end

end
