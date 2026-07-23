local Deck         = require("HMEng.entities.deck")
local CardZone     = require("HMEng.entities.board.cardzone")
-- local UIPanel     = require("HMEng.ui_actors.ui_panel")      = require("HMEng.ui_actors.ui_panel")
local Card, SND    = require("HMEng.entities.card"), require("HMfns.utils.sound_utils")
local Actor        = require("HMEng.actors.actor")
local EventMgr     = require("HMEng.events.event_mgr") 
local Controller   = require("HMEng.controller")
local PageAnimator = require("HMui.menu.transitions.page.animator")
local FileIO, C    = require("core.io.fileio"), require("HMfns.animate.color.color_const")
local TMR, SNDSrc  = require("HMfns.systems.timer"), require("HMEng.ch_mgr.snd.snd_src")

local fetch_snd, play_clip               = SNDSrc.fetch_snd_src, SND.play_clip
local pickle_load, unpickle, pickle_dump = FileIO.pickle_load, FileIO.unpickle, FileIO.pickle_dump

local LF, LS, LG, LT, LJ = love.filesystem, love.system, love.graphics, love.thread, love.joystick
local LTC, LTN, LF_rm    = LT.getChannel, LT.newThread, LF.remove

local cw = C.WHITE
local Y, N  = true, false

return function (GMgr)
-----------------------------
--- Start up
----------------------------------
--- Helper: load settings
function GMgr:_load_settings()
    local SET = self.SET
    local shared = unpickle((SET.save_data and SET.save_data.shared) or "shared.hm")
    local sets = (shared and shared.settings) or unpickle("settings.hm")

    if sets then for k, v in pairs(sets) do SET[k] = v end end
    SET.version, SET.pause, SET.queued_c = settings_ver or self.Ver, nil, {}

    if SET.s_graphics.s_texture then SET.s_graphics.s_texture = (SET.s_graphics.s_texture > 1 and 2) or 1 end
    SET.music_control = { desired_track = "", current_track = "", lerp = 1 }
end

--- Helper: init save mgr 
function GMgr:_init_save()
    self.SaveMgr  = { thread = LTN("HMEng/ch_mgr/save/save_manager.lua"), channel = LTC("save_request") }
    local SaveMgr = self.SaveMgr;                       SaveMgr.thread:start(2)

    local SD = self.SET.save_data or {}

    SD.slot_count = SD.slot_count or 10
    SD.root       = SD.root       or "saves"
    SD.shared     = SD.shared     or "shared.hm"
    SD.slots_root = SD.slots_root or (SD.root .. "/slots")

    self.SET.save_data = SD
    LF.createDirectory(SD.root)
    LF.createDirectory(SD.slots_root)
end

--- Helper: init snd channel
function GMgr:_init_snd()
    self.SndMgr  = { thread = LTN("HMEng/ch_mgr/snd/sound_manager.lua"), channel = LTC("sound_request"), load_channel = LTC("load_channel") }
    local SndMgr = self.SndMgr;                         SndMgr.thread:start(1)         
end

--- Helper: init controller 
function GMgr:_init_Ctrl()
    self.CTRL = Controller(self)
    LJ.loadGamepadMappings("resources/gamecontrollerdb.txt")
    if not self.F.rumble then return end 
    local joysticks = LJ.getJoysticks()
    if not joysticks    then return end  
    if not joysticks[1] then return end  
    self.CTRL:set_gamepad(joysticks[2] or joysticks[1])
end

--- Helper: init system actors
function GMgr:_init_system_actors()
    local prev_scope      = self.registry_scope
    self.registry_scope   = "system"
    -- self.p_cursor         = SpriteActor(self, 0, 0, 0.3, 0.3, self.a_atlas["centers"], { x = 0, y = 0 })
    self.p_cursor         = Actor(self, 0, 0, 0.3, 0.3)
    self.registry_scope   = prev_scope
    -- self.p_cursor.states.collide.can = N
end

-----------------------------
--- start_up
----------------------------------
function GMgr:start_up()
    local SET = self.SET

    --- settings and external data
    self:_load_settings()
    self.snd_src = fetch_snd()

    --- window and render resources
    self:init_window()
    self:init_shaders()

    --- threaded managers and input
    self:_init_save()
    self:_init_snd()
    self:_init_Ctrl()

    --- profile, language, and prototypes
    self:load_profile(SET.profile or 1)
    self:set_language()
    self:init_item_prototypes()
    self.sticker_map = { "White", "Red", "Green", "Black", "Blue", "Purple", "Orange", "Gold" }

    --- runtime ui and event state
    self:_init_system_actors()
    PageAnimator.preload(self)
    self._stage_suspend = N
    self.E_MANAGER = EventMgr(G)
    self.SET.sf = 1

    --- enter first stage
    set_profile_progress()
    self:splash_screen()
end

-----------------------------
--- splash screen 
----------------------------------
function GMgr:splash_screen() self:prep_stage(self.stages.title_page, self.g_states.splash, Y) end

end
