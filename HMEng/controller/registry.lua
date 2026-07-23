local const = require("core.const")
local TabUtils = require("HMfns.utils.table_utils")

local _copy = TabUtils.deep_copy
local pop, push = table.remove, table.insert

local Y, N = true, false

return function (Controller)
------------------------------------------------
--- Setup: Dynamically (changes with the progress) setup the game manager related registries
------------------------------------------------
function Controller:_setup(gm)
    self.gm = gm
    self._room,     self.R         = gm._room,         gm.R
    self.p_cursor,  self.CFOCUS    = gm.p_cursor,      gm.coyote_fcs
    self.g_state,   self.stop_use  = gm.g_state,       gm.GAME.STOP_USE
    self.hand,      self.play      = gm.hand,          gm.play
end

------------------------------------------------
--- emit intent 
------------------------------------------------
function Controller:emit_intent(intent_type, payload)
    if not intent_type then return end
    local intents = self.intents or {}
    self.intents = intents
    intents[#intents + 1] = { type = intent_type, payload = payload }
end

------------------------------------------------
--- drain intents
------------------------------------------------
function Controller:drain_intents()
    local intents = self.intents
    self.intents  = {}
    return intents
end

---------------------------------------------------
-- init the game manager related Registry
----------------------------------------------------
function Controller:init_registry(gm)
    local Fs = gm.Fs
    self.gm  = gm
    self.Fs  = { wipe = Fs.wipe, copy = Fs.deep_copy, xf_dist = Fs.xf_dist, contains = Fs.contains, on_keydown = Fs.on_text_input_keydown }
    
    self.rcfg,      self.g_states    = gm.rcfg,         gm.g_states             -- Registries
    self.min_cdist, self.min_ht      = const.min_cdist, const.min_h_time        -- Global const & setups
    self.args,      self.SET         = gm.args,         gm.SET
    self._T,        self.t_drawable  = gm._T,           gm.t_drawable
    self.t_actors,  self.PSglyphs    = gm.t_actors,     gm.Fs.PS4
    self.UI,        self.AATLAS      = gm.UI,           gm.a_atlas
end

-----------------------------------------------------
--- init input status 
-----------------------------------------------------
-- Helper 
local function _default_status() return { target = nil, handled = true, prev_target = nil } end
local function _cursor_status()  return { T = { x = 0, y = 0 }, target = nil, time = 0.1, handled = true } end
-- Main
function Controller:init_input_status()
    self.clicked,        self.focused          = _default_status(), _default_status()
    self.dragging,       self.hovering         = _default_status(), _default_status()
    self.released_on,    self.scrolled         = _default_status(), _default_status()
    self.collision_list, self.is_cursor_down   = {}, N
    self.cursor_down,    self.cursor_up        = _cursor_status(), _cursor_status() -- Cursor related 
    self.cursor_hover,   self.cursor_position  = _cursor_status(), { x = 0, y = 0 }
end

------------------------------------------------------
--- Init key button_registry
------------------------------------------------------
function Controller:init_key_button_registry()
    self.pressed_keys,       self.held_keys        = {}, {}                       
    self.held_key_times,     self.released_keys    = {}, {}
    self.pressed_buttons,    self.held_buttons     = {}, {}
    self.held_button_times,  self.released_buttons = {}, {}

    self.interrupt,    self.locks,   self.locked   = { focus = N },  {}, nil       -- Controller flow flags
    self.axis_buttons, self.axis_cursor_speed      = { l_stick = {}, r_stick = {}, l_trig = {}, r_trig = {} }, 20 -- Axis emulation state
    
    local ab, a_template  = self.axis_buttons, { current = "", previous = "" }

    for k, _ in pairs(ab) do ab[k] = _copy(a_template) end      -- Axis emulation state
    self.button_registry, self.snap_cursor_to    = {}, nil       -- Registries and contexts
    self.cursor_context,  self.cardarea_context  = { layer = 1, stack = {} }, {}
    self.gamepad_focus_scope, self.gamepad_camera_snap = "hand", { x = 0, y = 0 }
    self.intents                                 = {}

    self.HID  = { last_type = "", input_mode = "", dpad = N, pointer = Y, touch = N, controller = N, mouse = Y, axis_cursor = N }
    self.GAMEPAD, self.GAMEPAD_CONSOLE = { object = nil, mapping = nil, name = nil }, ""  --gamepad state
    self.keyboard_controller           = { getGamepadMappingString = function() return "" end, getGamepadAxis = function() return 0 end } -- Keyboard-as-gamepad fallback
end

------------------------------------------------------------------------
--- Cull Registry: remove all registries that no longer have valid nodes
------------------------------------------------------------------------
-- Helper: handle_registry
local function _handle_registry(registry)
    for i = #registry, 1, -1 do
        if not registry[i].node.REMOVED then goto continue end
        pop(registry, i)
        ::continue::
    end
end
--_____________________
-- Main: cull registry 
--_____________________
function Controller:cull_registry() for _, registry in pairs(self.button_registry) do _handle_registry(registry) end end

---------------------------------------------------------
-- Add to registry: Adds a node to the controller registry
----------------------------------------------------------
function Controller:add_to_registry(node, registry)
    local br, _act  = self.button_registry, not not (self.UI.overlay_menu or self.SET.pause)
    br[registry]    = br[registry] or {}
    push(br[registry], 1, { node = node, menu = _act })
end

--------------------------------------------------------------------------------
-- process_registry: Process registry Process click function of any nodes that have been clicked in the button registry
-----------------------------------------------------------------------------------------
-- Helper: handle button_registry
function Controller:_handle_button_registry(registry)
    local OM, R = self.UI.overlay_menu, self._room
    for i = 1, #registry do
        local entry    = registry[i]
        local en       = entry.node
        local enT, RT  = en.T, R.T
        local nclick   = en.click;          if not entry.click or not nclick then goto continue end 
        local _act, _inR = not not OM, enT.x > -2 and enT.x < RT.w + 2 and enT.y > -2 and enT.y < RT.h + 2
        if _act and _inR then ens:click() end
        entry.click = nil
        ::continue::
    end
end
-- Main
function Controller:process_registry() for _, registry in pairs(self.button_registry) do self:_handle_button_registry(registry) end end

end
